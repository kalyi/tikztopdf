#!/bin/bash
#
# Compiles a TikZ picture into a PDF document.
#
# Copyright (C) 2015, 2018 Kathrin Hanauer
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

######################################################################
# Source libraries.
######################################################################
source BashUtils
source ecla
######################################################################

######################################################################
# Variables
######################################################################
NAME="TikzToPdf"
VERSION="0.0.4"
DESC="Compiles a TikZ picture into a PDF document."
COMPILE_CMD=$(which pdflatex)
TEMPLATE=""
PREAMBLE=""
CONTENT=""
######################################################################

######################################################################
# Functions
######################################################################

###################
# setTemplate <TEMPLATEFILE>
setTemplate() {
  local FILE=$1
  debug "Trying to set template to \"${FILE}\"."
  if [ -z "${FILE}" ] || [ ! -f "${FILE}" ]
  then
    error "\"${FILE}\" is not a file."
  fi
  local ABSFILE=$(expand_filepath ${FILE})
  debug "Expanded ${FILE} to ${ABSFILE}."
  TEMPLATE=${ABSFILE} 
  return 0
}

###################
# setPreamble <PREAMBLEFILE>
setPreamble() {
  local FILE=$1
  debug "Trying to set preamble to \"${FILE}\"."
  if [ -z "${FILE}" ] || [ ! -f "${FILE}" ]
  then
    error "\"${FILE}\" is not a file."
  fi
  local ABSFILE=$(expand_filepath ${FILE})
  debug "Expanded ${FILE} to ${ABSFILE}."
  PREAMBLE=${ABSFILE} 
  return 0
}

###################
# setContent <CONTENTFILE>
setContent() {
  local FILE=$1
  debug "Trying to set content to \"${FILE}\"."
  if [ -z "${FILE}" ] || [ ! -f "${FILE}" ]
  then
    error "\"${FILE}\" is not a file."
  fi
  local ABSFILE=$(expand_filepath ${FILE})
  debug "Expanded ${FILE} to ${ABSFILE}."
  CONTENT=${ABSFILE}  
  return 0
}

###################
# buildPreambleImportString
buildPreambleImportString() {
  local PREAMBLE_DIR=$(extract_dir ${PREAMBLE})
  local PREAMBLE_FILE=$(extract_basename ${PREAMBLE})
  echo -E "\import{${PREAMBLE_DIR}/}{${PREAMBLE_FILE}}" 
}

###################
# buildContentImportString
buildContentImportString() {
  local CONTENT_DIR=$(extract_dir ${CONTENT})
  local CONTENT_FILE=$(extract_basename ${CONTENT})
  echo -E "\import{${CONTENT_DIR}/}{${CONTENT_FILE}}" 
}

###################
# createDefaultTemplateFile <FILEPATH>
createDefaultTemplate() {
  local FILEPATH=$1
  cat << EOF > ${FILEPATH}
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{tikz}
\usepackage{import}
\usepackage[active,tightpage]{preview}
EOF
  if [ -n "${PREAMBLE}" ]
  then
    local PREAMBLE_IMPORT=$(buildPreambleImportString)
    echo -E "${PREAMBLE_IMPORT}" >> ${FILEPATH}
  fi
  cat << EOF >> ${FILEPATH}
\begin{document}
\begin{preview}
\begin{tikzpicture}
EOF
  local CONTENT_IMPORT=$(buildContentImportString)
  echo -E "${CONTENT_IMPORT}" >> ${FILEPATH}
cat << EOF >> ${FILEPATH}
\end{tikzpicture}
\end{preview}
\end{document}
EOF
}

###################
# useCustomTemplate <FILEPATH>
useCustomTemplate() {
  local FILEPATH=$1
  cp ${TEMPLATE} ${FILEPATH}

  if [ -n "${PREAMBLE}" ]
  then
    local PREAMBLE_IMPORT=$(buildPreambleImportString)
    PREAMBLE_IMPORT=$(echo ${PREAMBLE_IMPORT} | sed -e 's/[\/&]/\\&/g')
    debug "sed -i \"s/^% {T2P:PREAMBLE}/${PREAMBLE_IMPORT}/\" ${FILEPATH}"
    sed -i "s/^% {T2P:PREAMBLE}/${PREAMBLE_IMPORT}/" ${FILEPATH}
  fi

  local CONTENT_IMPORT=$(buildContentImportString)
  CONTENT_IMPORT=$(echo ${CONTENT_IMPORT} | sed -e 's/[\/&]/\\&/g')
  debug "sed -i \"s/^% {T2P:CONTENT}/${CONTENT_IMPORT}/\" ${FILEPATH}"
  sed -i "s/^% {T2P:CONTENT}/${CONTENT_IMPORT}/" ${FILEPATH}
}

###################
# findPreamble
findPreamble() {
  local CANDIDATES=(preamble.t2p.tex preamble.t2p ~/.preamble.t2p)
  for c in ${CANDIDATES}
  do
    if [ -f "$c" ]
    then
      setPreamble $c
      return 0
    fi
  done
  return 1
}

###################
# copyCustomPackages
copyCustomPackages() {
  local TMPDIR=$1

	CLS=$(grep documentclass ${TMPDIR}/* | sed -e 's/.*\\documentclass[^{]*{\([A-Za-z0-9\./]*\)}/\1/')
	for C in ${CLS}
	do
		CFILE=${C}.cls
		if [ -f ${CFILE} ]
		then
			if [[ $PFILE =~ "/" ]]
			then
				error "Relative paths to classes are currently unsupported (class: ${C})"
			fi
			debug "Copying ${CFILE} to temporary directory."
			cp ${CFILE} ${TMPDIR}/
		fi
	done

	PKGS=$(grep usepackage ${TMPDIR}/* | sed -e 's/.*\\usepackage[^{]*{\([A-Za-z0-9\./]*\)}/\1/')
	for P in ${PKGS}
	do
		PFILE=${P}.sty
		if [ -f ${PFILE} ]
		then
			if [[ $PFILE =~ "/" ]]
			then
				error "Relative paths to packages are currently unsupported (package: ${P})"
			fi
			debug "Copying ${PFILE} to temporary directory."
			cp ${PFILE} ${TMPDIR}/
		fi
	done
}

###################
# cleanup
function cleanup {
  if [ "${DEBUG}" -eq 0 ] && [ -d "${TMPDIR}" ]
	then
		debug "Cleanup up temporary directory ${TMPDIR}..."
  	rm -rf "${TMPDIR}"
  fi
}


###################
# compile
compile() {
  if [ -z "${CONTENT}" ]
  then
    error "No content specified."
  fi

  if [ -z "${PREAMBLE}" ]
  then
    findPreamble
  fi

  local F_TEMPLATE="template.tex"
  local F_PREAMBLE="preamble.tex"
  local F_CONTENT="content.tex"
  local F_RESULT="template.pdf"

	trap cleanup EXIT

  TMPDIR=$(mktemp -d)
  debug "Created temporary directory ${TMPDIR}."
  local PDFFILE=$(extract_base ${CONTENT})
  PDFFILE=$(extract_base ${PDFFILE}).pdf
  debug "PDF file will be named ${PDFFILE}."

  if [ -z "${TEMPLATE}" ]
  then
    createDefaultTemplate ${TMPDIR}/${F_TEMPLATE}
  else
    useCustomTemplate ${TMPDIR}/${F_TEMPLATE}
  fi

	copyCustomPackages ${TMPDIR}


  local CURDIR=$(pwd)
  local CCMD="TEXINPUTS=\"${CURDIR}//:\" ${COMPILE_CMD} ${TMPDIR}/${F_TEMPLATE}"

  if [ ${DEBUG} -eq 0 ]
  then
    cd ${TMPDIR}
		eval ${CCMD} && eval ${CCMD} && cp ${TMPDIR}/${F_RESULT} ${CURDIR}/${PDFFILE}
    cd ${CURDIR}
    rm -r ${TMPDIR}
  else
    debug "Debug mode enabled. Please compile and cleanup yourself :)"
    debug "Compile command would be: ${CCMD}"
  fi
}



######################################################################
# MAIN
######################################################################

ecla_init "${NAME}" "${VERSION}" "${DESCRIPTION}"
ecla_add_argument "t" "FILE" "the template file." "setTemplate"
ecla_add_argument "p" "FILE" "the preamble file." "setPreamble"
ecla_add_argument "i" "FILE" "the input/content file." "setContent"
ecla_add_argument_noparam "d" "enable debug mode." "enableDebugMode"

ecla_parse "${@}"
NONARGS=$(ecla_unprocessed_args)
debug "Unprocessed arguments are ${NONARGS}"
if [ -z "${CONTENT}" ]
then
  if [ -n "${NONARGS[0]}" ]
  then
    setContent ${NONARGS[0]}
  else
    error "No input file given. Try -h for help."
  fi
fi

compile
