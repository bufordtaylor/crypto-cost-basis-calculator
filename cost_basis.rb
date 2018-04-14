# Copyright 2018 Krishna Ramachandran
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

require 'date'

# Class used to track gain loss for one or many sells from an Asset purchase
class GainLoss
  @amount = 0.0 # negative value indicates loss
  @type = nil # short term or long term gain/loss
  @selldate = nil
  @units_sold = 0.0
  
  attr_reader :amount, :type, :selldate, :units_sold

  def initialize(selldate, units_sold, amount, type)
    @amount = amount
    @type = type
    @selldate = selldate
    @units_sold = units_sold
  end
end

# Class used to track each asset purchased
class Asset
  @currency = nil
  @original_units = 0.0 # original units bought
  @unit_price = 0.0 # price per unit
  @amount_spent = 0.0 # total amount spent
  @buydate = nil
  @remaining_units = 0.0 # units remaining if any after any sales of fraction units from this asset
  @gain_loss = nil # Array to store various gains and losses, represented with the GainLoss class.
  
  attr_reader :currency, :original_units, :unit_price, :amount_spent, :buydate, :remaining_units, :gain_loss
  attr_writer :remaining_units
  
  def initialize(currency_type, date_bought, units, amount_spent)
    @currency = currency_type
    @buydate = date_bought
    @original_units = units
    @amount_spent = amount_spent
    @unit_price = amount_spent/units
    @remaining_units = @original_units
    @gain_loss = Array.new
  end
  
  def to_s
    print "Bought #{@original_units} of asset #{@currency} on #{@buydate}. Amount spent - #{@amount_spent}. Unit cost - #{@unit_price}. Remaining units - #{@remaining_units}\n"
    gain_loss.each { |pl|
      print "Gained #{pl.amount} of type #{pl.type} with #{pl.units_sold} sold on #{pl.selldate}\n"
    }
  end
end

# Class to represent each sell
class Sell
  @currency = nil
  @units_sold = 0.0
  @amount = 0.0
  @selldate = nil
  @unit_price = nil
  @remaining_units = 0.0
  
  attr_reader :currency, :units_sold, :amount, :selldate, :unit_price, :remaining_units
  attr_writer :remaining_units
  
  def initialize(date, currency_type, units, amount)
    @currency = currency_type
    @selldate = date
    @units_sold = units
    @amount = amount
    @unit_price = amount/units
    @remaining_units = @units_sold
  end
  
  def to_s
    print "Sold asset #{@currency} on #{@selldate}. Amount made - #{@amount}. Units sold - #{@units_sold} at unit price #{@unit_price}\n"
  end
end

# Main entry point
filename = ARGV[0]
if filename == nil
  puts "Error: Coinbase input file missing\nUsage: ruby cost_basis.rb <Coinbase consolidated report.csv>"
	exit
end

buys = Array.new
sells = Array.new

f = File.open(filename, "r:UTF-8:iso-8859-1")
f.each_line do |line|
	parts = line.split(',')
  # Rudimentary checks to ensure we are only parsing buys, sells and sends
  if parts.count < 8 || parts[0] !~ /\d+/
    next
  end
  if parts[1] == "Buy"
    a = Asset.new(parts[2], parts[0], parts[3].to_f, parts[5].to_f)
    buys.unshift a # Store the buys in reverse chronological order for LIFO processing
  elsif parts[1] == "Sell"
    s = Sell.new(parts[0], parts[2], parts[3].to_f, parts[5].to_f)
    sells.unshift s # Store the sells in reverse chronological order for LIFO processing
  elsif parts[2] == "Send"
    # Sends to be manually accounted for since the destination of the send and what you do with it is unknown to Coinbase
  end
end
f.close

# Iterate through all sells to calculate cost basis
sells.each { |s|
  
  # only look at sells in 2017
  sell_date = Date.strptime(s.selldate, '%m/%d/%Y')
  if sell_date < Date.strptime("2017-01-01", '%Y-%m-%d') || sell_date >= Date.strptime("2018-01-01", '%Y-%m-%d')
    next
  end

  # Look through all buys, which are stored in reverse chronological order, and determine which most recent buy can be used
  # as cost basis for the current sell
  buys.each { |b|
    buy_date = Date.strptime(b.buydate, '%m/%d/%Y')
    # only look at buys before sell date
    if buy_date > sell_date
      next
    end
    
    # asset currency must be a match, otherwise continue
    if b.currency != s.currency
      next
    end
    
    # check if the underlying asset still has units available for it to be used against this sell
    if b.remaining_units < 0.00000001 # smallest unit of BTC, ETH and LTC is 1/10^8. So skip anything that's smaller than that
      next
    end
    
    type = "short term"
    if sell_date - buy_date > 365
      type = "long term"
    end
    
    # Main LIFO logic
    if b.remaining_units > s.remaining_units
      g = GainLoss.new(s.selldate, s.remaining_units, s.remaining_units * (s.unit_price - b.unit_price), type)
      b.gain_loss << g
      b.remaining_units = b.remaining_units - s.remaining_units
      break
    else
      g = GainLoss.new(s.selldate, b.remaining_units, b.remaining_units * (s.unit_price - b.unit_price), type)
      b.gain_loss << g
      s.remaining_units = s.remaining_units - b.remaining_units
      b.remaining_units = 0.0
    end
  }
}

# iterate through all purchases and print out any gains
print "Buy date, Asset, Units, Cost Basis, Sell Date, Sold Price, Gain/Loss, Gain/Loss Type\n"
ascending_buys = buys.reverse
ascending_buys.each { |b|
  b.gain_loss.each { |pl|
    print "#{b.buydate},#{b.currency},#{pl.units_sold},#{pl.units_sold * b.unit_price},#{pl.selldate},#{pl.units_sold * b.unit_price + pl.amount},#{pl.amount},#{pl.type}\n"
  }
  # This are assets that are still available for future sells. Use these for future tax years.
  if b.remaining_units >= 0.00000001
    print "#{b.buydate},#{b.currency},#{b.remaining_units},#{b.remaining_units * b.unit_price},-,-,-,-\n"
  end
}

