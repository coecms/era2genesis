#!/usr/bin/env bash

year="2000"
month="01"
day="01"

# File name for u-component of wind will be ${file_prefix}_u.nc
file_prefix="holger"

# Area around the relevant column
# NOTE: Always use floating points. Otherwise it will not work.
# will be used in ncks -d ...,${LATRANGE}
LATRANGE="-37.5,-34.5"
LONRANGE="146.25,150.0"


#Time 
TIMERANGE="0,33"

module load netcdf nco cdo python


PATH_TO_ERA_FILES="/g/data1/ua8/erai/netcdf/oper_an_pl/fullres/sub-daily/${year}"
WORK_DIR="/short/${PROJECT}/${USER}/scm/data2"


UFILE="${WORK_DIR}/${file_prefix}_u.nc"
VFILE="${WORK_DIR}/${file_prefix}_v.nc"
TFILE="${WORK_DIR}/${file_prefix}_temp.nc"
ZFILE="${WORK_DIR}/${file_prefix}_ht.nc"
QFILE="${WORK_DIR}/${file_prefix}_q.nc"
MSPFILE="${WORK_DIR}/${file_prefix}_msp.nc"

FILES3D="${UFILE} ${VFILE} ${ZFILE} ${QFILE}"

for field in U V T Q Z ; do
  echo "${field}... "
  INFILE="${PATH_TO_ERA_FILES}/${field}_6hrs_pl_${year}_${month}.nc"
  case ${field} in
    "U")
      OUTFILE=${UFILE}
      INVARNAME="U_GDS0_ISBL"
      VARNAME="u"
      ;;
    "V")
      OUTFILE=${VFILE}
      INVARNAME="V_GDS0_ISBL"
      VARNAME="v"
      ;;
    "T")
      OUTFILE=${TFILE}
      INVARNAME="T_GDS0_ISBL"
      VARNAME="temp"
      ;;
    "Z")
      OUTFILE=${ZFILE}
      INVARNAME="Z_GDS0_ISBL"
      VARNAME="ht"
      ;;
    "Q")
      OUTFILE=${QFILE}
      INVARNAME="Q_GDS0_ISBL"
      VARNAME="q"
      ;;
    "MSP")
      OUTFILE=${MSPFILE}
      INVARNAME="MSL_GDS0_SFC"
      VARNAME="p"
      ;;
    *)
      echo "field not found. exiting"
      exit 1
      ;;
  esac
  case ${field} in 
    "U"|"V"|"T"|"Z"|"Q")
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
    DIMRENAMES="${DIMRENAMES} -d lv_ISBL1,pint"
  fi
  VARRENAMES="${DIMRENAMES//-d/-v} -v ${INVARNAME},${VARNAME}short"
  ncrename -O ${DIMRENAMES} ${VARRENAMES} ${OUTFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi

  echo "Step 3: inverting some dimesions"
  ncpdq -O -a -latitude ${OUTFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong while inverting latitude for ${field}. Exiting"
    exit 1
  fi
  if [[ "$DIM" == "3D" ]]; then
    ncpdq -O -a -pint ${OUTFILE} ${OUTFILE}
    RC=$?
    if [[ "$RC" != "0" ]]; then
      echo "Something went wrong while inverting pressure levels for ${field}. Exiting"
      exit 1
    fi
  fi

  echo "Step 4: Change time dimension"
  DAYS_DIFFERENCE=`calc_difference.py -o 1800-01-01 -n ${year}-${month}-${day}`
  ncap2 -O -s "t=float((t/24.)-${DAYS_DIFFERENCE})" -s "t@units=\"days since ${year}-${month}-${day} 00:00\"" ${OUTFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi

  echo "Step 5: Convert everything to float"
  ncap2 -O -s "${VARNAME}=float(${VARNAME}short)" ${OUTFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi
  if [[ "$DIM" == "3D" ]]; then
    ncap2 -O -s "p=float(pint)" ${OUTFILE} ${OUTFILE}
    RC=$?
    if [[ "$RC" != "0" ]]; then
      echo "Something went wrong while converting pressure levels for ${field}. Exiting"
      exit 1
    fi
    ncrename -O -d pint,p ${OUTFILE} ${OUTFILE}
  fi

  echo "Step 6: removing superfluous fields"

  VARS_TO_DELETE="-v ${VARNAME}short,initial_time0,initial_time0_encoded"
  if [[ "$DIM" == "3D" ]] ; then
    VARS_TO_DELETE="${VARS_TO_DELETE},pint"
  fi
  ncks -O -x ${VARS_TO_DELETE} ${OUTFILE} ${OUTFILE}
  RC=$?
  if [[ "$RC" != "0" ]]; then
    echo "Something went wrong. Exiting"
    exit 1
  fi


  echo "done"
done

