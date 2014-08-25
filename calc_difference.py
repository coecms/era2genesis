#!/usr/bin/env python
from datetime import datetime
from optparse import OptionParser

def calc_difference(old, new):
  """ (date, date) -> int
  returns the number of days between old and new

  >>> old = datetime.strptime('2000-01-01', '%Y-%m-%d')
  >>> new = datetime.strptime('2000-01-02', '%Y-%m-%d')
  >>> calc_difference(old, new)
  1
  >>> new = datetime.strptime('2000-02-01', '%Y-%m-%d')
  >>> calc_difference(old, new)
  31
  """
  return (new-old).days

def main():
  parser=OptionParser()
  parser.add_option('-o', '--original', help='Original date')
  parser.add_option('-n', '--new', help='New date')
  (opts, args) = parser.parse_args()

  old_time = datetime.strptime(opts.original, '%Y-%m-%d')
  new_time = datetime.strptime(opts.new, '%Y-%m-%d')
  print calc_difference(old_time, new_time)

if __name__ == '__main__':
  #import doctest
  #doctest.testmod()
  main()

