#!/usr/bin/env bash

year="2000"
month="01"

# File name for u-component of wind will be ${file_prefix}_u.nc
file_prefix="holger"

# Area around the relevant column
# NOTE: Always use floating points. Otherwise it will not work.
# will be used in ncks -d ...,${LATRANGE}
LATRANGE="-37.5,-34.5"
LONRANGE="146.25,150.0"


#Time 
TIMERANGE="0,33"

module load netcdf nco cdo


PATH_TO_ERA_FILES="/g/data1/ua8/erai/netcdf/oper_an_pl/fullres/sub-daily/${year}"
WORK_DIR="/short/${PROJECT}/${USER}/scm/data2"

echo "Step 1: Extract data from ERA files"

UFILE="${WORK_DIR}/${file_prefix}_u.nc"
VFILE="${WORK_DIR}/${file_prefix}_v.nc"
ZFILE="${WORK_DIR}/${file_prefix}_ht.nc"
QFILE="${WORK_DIR}/${file_prefix}_q.nc"
MSPFILE="${WORK_DIR}/${file_prefix}_msp.nc"

#3DFILES="${UFILE} ${VFILE} ${ZFILE} ${QFILE}"

for field in U V Q Z MSP ; do
  echo "${field}... "
  INFILE="${PATH_TO_ERA_FILES}/${field}_6hrs_pl_${year}_${month}.nc"
  case ${field} in
    "U")
      OUTFILE=${UFILE}
      ;;
    "V")
      OUTFILE=${VFILE}
      ;;
    "Z")
      OUTFILE=${ZFILE}
      ;;
    "Q")
      OUTFILE=${QFILE}
      ;;
    "MSP")
      OUTFILE=${MSPFILE}
      ;;
    *)
      echo "field not found. exiting"
      exit 1
      ;;
  esac
  case ${field} in 
    "U"|"V"|"Z"|"Q")
      LATNAME="g0_lat_2"
      LONNAME="g0_lon_3"
      TIMENAME="initial_time0_hours"
      ;;
    "MSP")
      LATNAME="g0_lat_1"
      LONNAME="g0_lon_2"
      TIMENAME="initial_time0_hours"
      ;;
  esac

  echo ncks -d ${LATNAME},${LATRANGE} -d ${LONNAME},${LONRANGE} -d ${TIMENAME},${TIMERANGE} ${INFILE} ${OUTFILE}
  ncks -d ${LATNAME},${LATRANGE} -d ${LONNAME},${LONRANGE} -d ${TIMENAME},${TIMERANGE} ${INFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi
  echo "done"
done

