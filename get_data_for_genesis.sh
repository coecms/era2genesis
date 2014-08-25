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


UFILE="${WORK_DIR}/${file_prefix}_u.nc"
VFILE="${WORK_DIR}/${file_prefix}_v.nc"
ZFILE="${WORK_DIR}/${file_prefix}_ht.nc"
QFILE="${WORK_DIR}/${file_prefix}_q.nc"
MSPFILE="${WORK_DIR}/${file_prefix}_msp.nc"

FILES3D="${UFILE} ${VFILE} ${ZFILE} ${QFILE}"

for field in U V Q Z ; do
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
      DIM="3D"
      ;;
    "MSP")
      LATNAME="g0_lat_1"
      LONNAME="g0_lon_2"
      TIMENAME="initial_time0_hours"
      DIM="2D"
      ;;
  esac

  echo "Step 1: Extract data from ERA files"
  ncks -d ${LATNAME},${LATRANGE} -d ${LONNAME},${LONRANGE} -d ${TIMENAME},${TIMERANGE} ${INFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi


  echo "Step 2: renaming dimensions."
  DIMRENAMES="-d ${LATNAME},latitude -d ${LONNAME},longitude -d ${TIMENAME},t"
  if [[ "$DIM" == "3D" ]]; then
    # Adding height dimension to rename list
    DIMRENAMES="${DIMRENAMES} -d lv_ISBL1,p"
  fi
  VARRENAMES="${DIMRENAMES//-d/-v}"
  ncrename -O ${DIMRENAMES} ${VARRENAMES} ${OUTFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi

  echo "Step 3: inverting some dimesions"
  ncpdq -O -a -latitude ${OUTFILE} ${OUTFILE}
  if [[ "$DIM" == "3D" ]]; then
    ncpdq -O -a -p ${OUTFILE} ${OUTFILE}
  fi



  echo "done"
done

