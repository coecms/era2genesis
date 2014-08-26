#!/usr/bin/env python
from datetime import datetime,timedelta
from optparse import OptionParser

def main():
  parser=OptionParser()
  parser.add_option('-s', '--start', help="Start date")
  parser.add_option('-n', '--number', help="Number of dates")
  (opts, args) = parser.parse_args()

  t=datetime.strptime(opts.start, '%Y-%M-%d')
  delta_time=timedelta(hours=6)

  for i in range(int(opts.number)):
    print( t.strftime(' %Y%M%d %H') )
    t += delta_time

if __name__ == '__main__':
  main()
