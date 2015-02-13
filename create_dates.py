#!/usr/bin/env python
from datetime import datetime,timedelta
from optparse import OptionParser
import copy

def create_dates(start, n):
  """(datetime, int) -> list of str

  Creates a list of strings of the form "20040201  00" (YYYYMMDD  HH)
  of 6 hour intervals beginning with start time start, and having n 
  elements.

  >>> start = datetime(2004, 02, 25, 00)
  >>> result = create_dates( start, 10 )
  >>> for s in result: print "|"+s+"|"
  | 20040225  00|
  | 20040225  06|
  | 20040225  12|
  | 20040225  18|
  | 20040226  00|
  | 20040226  06|
  | 20040226  12|
  | 20040226  18|
  | 20040227  00|
  | 20040227  06|

  >>> start = datetime(2004, 02, 28, 00)
  >>> result = create_dates( start, 10 )
  >>> for s in result: print "|"+s+"|"
  | 20040228  00|
  | 20040228  06|
  | 20040228  12|
  | 20040228  18|
  | 20040229  00|
  | 20040229  06|
  | 20040229  12|
  | 20040229  18|
  | 20040301  00|
  | 20040301  06|

  >>> start = datetime(2004, 02, 28, 12)
  >>> result = create_dates( start, 8 )
  >>> for s in result: print "|"+s+"|"
  | 20040228  12|
  | 20040228  18|
  | 20040229  00|
  | 20040229  06|
  | 20040229  12|
  | 20040229  18|
  | 20040301  00|
  | 20040301  06|
  """

  dt = timedelta(hours=6)

  return_list = []

  t = copy.deepcopy(start)

  for i in range(n):
    return_list.append(t.strftime( ' %Y%m%d  %H' ))
    t += dt

  return return_list

def export_dates_inp(start, n, dir):
  """(datetime, int, str) -> datetime

  Writes the dates.dat file, and returns a datetime of the last element of that file

  >>> import os
  >>> os.system("test -d ./delme || mkdir ./delme")
  0
  >>> start = datetime(2004, 02, 28, 12)
  >>> export_dates_inp( start, 8, './delme' )
  datetime.datetime(2004, 3, 1, 6, 0)
  """

  dates = create_dates(start, n)

  with open(dir + '/dates.dat', 'w') as datefile:
    for item in dates:
      datefile.write(item + '\n')
  datefile.close()

  return start + timedelta(hours = 6 * (n-1))


def export_base_inp(start, end, dir):
  template = """ &BASE
  z_terrain_asl=436,nzum=38
 /
 &VERTLEVS
  Z_TOP_OF_MODEL= 39254.833576,
  FIRST_CONSTANT_R_RHO_LEVEL=30,
  ETA_THETA= 0.0,
 .0005095,  .0020380,  .0045854,  .0081519,  .0127373,
 .0183417,  .0249651,  .0326074,  .0412688,  .0509491,
 .0616485,  .0733668,  .0861040,  .0998603,  .1146356,
 .1304298,  .1472430,  .1650752,  .1839264,  .2037966,
 .2246857,  .2465938,  .2695209,  .2934670,  .3184321,
 .3444162,  .3714396,  .3998142,  .4298913,  .4620737,
 .4968308,  .5347160,  .5763897,  .6230643,  .6772068,
 .7443435,  .8383348, 1.0000000,
  ETA_RHO=
 .0002547,  .0012737,  .0033117,  .0063686,  .0104446,
 .0155395,  .0216534,  .0287863,  .0369381,  .0461090,
 .0562988,  .0675076,  .0797354,  .0929822,  .1072479,
 .1225327,  .1388364,  .1561591,  .1745008,  .1938615,
 .2142411,  .2356398,  .2580574,  .2814940,  .3059496,
 .3314242,  .3579279,  .3856269,  .4148527,  .4459825,
 .4794523,  .5157734,  .5555529,  .5997270,  .6501355,
 .7107751,  .7913392,  .9191674,
 /
 &USRFIELDS_1
 UI=		.true.,
 VI=		.true.,
 WI=		.false.,
 THETA=		.true.,
 QI=		.true.,
 P_IN=		.true.
 /
 &USRFIELDS_2
 L_windrlx=	.false.,
 TAU_RLX=	.true.,
 L_vertadv=	.false.,
 TSTAR_FORCING=	.false.,
 FLUX_E=	.false.,
 FLUX_H=	.false.,
 U_INC=		.true.,
 V_INC=		.true.,
 W_INC=		.false.,
 T_INC=		.true.,
 Q_STAR=	.true.,
 ichgf=		.true.
 /
 &USRFIELDS_3
 namelist_template = '/short/w35/hxw599/scm/data2/template.scm'
 /
 &TIME
 sdate={sdate:8},shour={shour:2},edate={edate:8},ehour={ehour:2},
 year={syear:4},month={smonth:2},day={sday:2}
 /
"""
  base=open(dir + '/base.inp', 'w')
  base.write( template.format(sdate=start.strftime('%Y%m%d'), shour=start.strftime('%H'),
                        edate=end.strftime('%Y%m%d'), ehour=end.strftime('%H'),
                        syear=start.strftime('%Y'), smonth=start.strftime('%m'), 
                        sday=start.strftime('%d') ))
  base.close()

def main():
  parser=OptionParser()
  parser.add_option('-s', '--start', help="Start date")
  parser.add_option('-n', '--number', help="Number of dates")
  parser.add_option('-d', '--dir', help="Work Directory")
  parser.add_option('--test', help="Unit Test this script", action="store_true", default=False)
  (opts, args) = parser.parse_args()

  if opts.test:
    import doctest
    doctest.testmod()
  else:
    start_time=datetime.strptime(opts.start, '%Y-%m-%d')
    end_time = export_dates_inp(start_time, int(opts.number), opts.dir)
    export_base_inp(start_time, end_time, opts.dir)

if __name__ == '__main__':
  main()
