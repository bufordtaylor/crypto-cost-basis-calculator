# Last In First Out (LIFO) Cost Basis Calculator For Coinbase

Coinbase's tax reporting [solution](https://blog.coinbase.com/new-tax-tools-on-coinbase-4d2598544d9e) as of today reports cost basis in a first in first out (FIFO) order. This isn't the best in a rising price environment and may result in you overpaying your taxes. 

This script was written to compute cost basis in a last in first out order. This helped me save taxes. It also alleviated a lot of headache and time because the alternative was to do this manually and that got very gnarly very quickly. 

# Important disclaimers 
Seeing this has to do with the IRS and all, I'd be remiss if I didn't mention the following:

1. I'm not a tax expert, and I did not consult a tax expert when writing this script. 
2. Since I'm not a tax expert, I haven't accounted for various nuances, such as [wash sales](https://www.sec.gov/answers/wash.htm). 
3. Your mileage may vary. As this [post](https://bravenewcoin.com/news/capital-gains-on-cryptocurrency-fifo-lifo-or-specific-identification/) points out, there's several options (FIFO, specified lot, LIFO, average, etc) for calculating your cost basis. LIFO worked well for my situation, and that's what this script does. If you extend this script to support some of the other methods, please drop me a note or do a pull request in this repo and I'll incorporate your changes.
4. You assume any and all risk with use of this script. I offer no warranties of any kind, express or implied. 
# License
This script is offered under an [MIT license](https://opensource.org/licenses/MIT). 

# Usage
You must have [Ruby](https://www.ruby-lang.org/en/) to run this script. See [here](https://www.ruby-lang.org/en/documentation/installation/) for installation instructions.

To execute the script, open a terminal window and run the following command:

```

ruby cost_basis.rb <your coinbase transaction history file> > result.csv`

```

# How to get your coinbase transaction history file?
Here's how to get your coinbase transaction history file. Login to coinbase and navigate to "Tools -> "Tax Center". Then generate a new report as shown below and download the generated file and use it on the terminal command line as shown above.

If you edit the file in a program like Microsoft Excel, the formatting of the date can change and that'll throw my script off. So try and edit the doc in it's raw CSV file format as much as possible if you are making any edits to the coinbase transaction history file. Reasons to make edits to the coinbase transaction file could be because you have some transactions on GDAX or other exchanges that you want to consolidate into one transaction history file.

![Coinbase download instructions](https://github.com/nrkrishna/crypto-cost-basis-calculator/blob/master/coinbase_download_instructions.png)

# Output
Your result file will look like the below sample. It essentially lists all of your buys with the following additional information:
1. The date the corresponding units were sold
2. The price at which you sold those units. 
3. Your gain or loss amount. Losses are negative in value.
4. Whether your gain/loss is short-term or long-term. 

For any buys that weren't sold, the above information is empty. In the sample below, the fourth row is BTC that was bought but hasn't been sold yet.

```
Buy date, Asset, Units, Cost Basis, Sell Date, Sold Price, Gain/Loss, Gain/Loss Type
3/10/16, BTC, 0.02546471, 10.0, 1/3/17, 26.17, 16.17, short term
09/14/17, ETH, 0.49453945, 124.99, 11/28/17, 190.77, 64.77, short term
10/12/17, LTC, 1.16035209, 75.0, 11/30/17, 115.32, 37.32, short term
1/12/16, BTC, 0.02164835, 10.0, , , , 
```

It's *important* that you save your result file and use it for future years' cost basis calculations. 

# Feedback
If you have any feedback on this script, please tweet me at @krishna_nr. 
