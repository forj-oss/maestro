# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# This script contains way to load build configuration.
# 

CONFIG_PATH=. # By default search for configuration files on the current directory

GITBRANCH=master

declare -a VAR_DEF
declare -a VAR_VAL

VAR_DEF[1]="FORJ_HPC_COMPUTE"        ; VAR_VAL[1]="compute"
VAR_DEF[2]="FORJ_HPC_OBJECT_STORAGE" ; VAR_VAL[2]="object storage"
VAR_DEF[3]="FORJ_HPC_CDN"            ; VAR_VAL[3]="cdn"
VAR_DEF[4]="FORJ_HPC_BLOCK_STORAGE"  ; VAR_VAL[4]="block storage"
VAR_DEF[5]="FORJ_HPC_DNS"            ; VAR_VAL[5]="dns"
VAR_DEF[6]="FORJ_HPC_LOAD_BALANCER"  ; VAR_VAL[6]="load balancer"
VAR_DEF[7]="FORJ_HPC_MONITORING"     ; VAR_VAL[7]="monitoring"
VAR_DEF[8]="FORJ_HPC_NETWORKING"     ; VAR_VAL[8]="networking"
VAR_DEF[9]="FORJ_HPC_DB"             ; VAR_VAL[9]="relational db mysql"
VAR_DEF[10]="FORJ_HPC_REPORTING"     ; VAR_VAL[10]="usage reporting"
VAR_DEF[11]="FORJ_HPC_TENANTID"      ; VAR_VAL[11]="tenant_id"
HPC_MAX=11

function HPC_Check()
{
 if [ "$ERO_FLAVOR" != "" ]
 then
    Warning "ERO_FLAVOR definition variable is obsolete. Use FORJ_FLAVOR variable instead."
    if [ "$FORJ_FLAVOR" = "" ]
    then
       Info "FORJ_FLAVOR was set to $ERO_FLAVOR (ERO_FLAVOR definition)"
       FORJ_FLAVOR="$ERO_FLAVOR"
    fi
 fi

 if [ "$CDK_BUILD_HPC" != "" ]
 then
    Warning "CDK_BUILD_HPC definition variable is obsolete. Use FORJ_HPC variable instead."
    if [ "$FORJ_HPC" = "" ]
    then
       Info "FORJ_HPC was set to $CDK_BUILD_HPC (CDK_BUILD_HPC definition)"
       FORJ_HPC="$CDK_BUILD_HPC"
    fi
 fi
 if [ "$TENANT_ID" != "" ]
 then
    Warning "TENANT_ID definition variable is obsolete. Use FORJ_HPC_TENANTID variable instead."
    if [ "$FORJ_HPC_TENANTID" = "" ]
    then
       Info "FORJ_HPC_TENANTID was set to $TENANT_ID (TENANT_ID definition)"
       FORJ_HPC_TENANTID="$TENANT_ID"
    fi
 fi
 if [ "$CDK_BASE_IMG" != "" ]
 then
    Warning "CDK_BASE_IMG definition variable is obsolete. Use FORJ_HPC_BASE_IMG variable instead."
    if [ "$FORJ_HPC_BASE_IMG" = "" ]
    then
       Info "FORJ_HPC_BASE_IMG was set to $CDK_BASE_IMG (CDK_BASE_IMG definition)"
       FORJ_BASE_IMG="$CDK_BASE_IMG"
    fi
 fi
 if [ "$CDK_BUILD_ZONE" != "" ]
 then
    Warning "CDK_BUILD_ZONE definition variable is obsolete. Use FORJ_HPC_COMPUTE and FORJ_HPC_BLOCK_STORAGE variables instead."
    if [ "$FORJ_HPC_COMPUTE" = "" ]
    then
       Info "FORJ_HPC_COMPUTE was set to $CDK_BUILD_ZONE (CDK_BUILD_ZONE definition)"
       FORJ_HPC_COMPUTE="$CDK_BUILD_ZONE"
    fi
    if [ "$FORJ_HPC_BLOCK_STORAGE" = "" ]
    then
       Info "FORJ_HPC_BLOCK_STORAGE was set to $CDK_BUILD_ZONE (CDK_BUILD_ZONE definition)"
       FORJ_HPC_BLOCK_STORAGE="$CDK_BUILD_ZONE"
    fi
 fi
}

function HPC_Verify()
{
 typeset -i iCount=1
 
 # Check $FORJ_HPC data
 NODIFF=True
 while [ $iCount -le $HPC_MAX ]
 do
   eval "VALUE=\"\$${VAR_DEF[$iCount]}\""
   if [ "$VALUE" != "" ]
   then
      eval "REF='${VAR_VAL[$iCount]}'"
      CHECK="  :$REF: '*$VALUE'*"
      if [ "$(grep -e "$CHECK" ~/.hpcloud/accounts/$FORJ_HPC)" = "" ]
      then
         hpcloud account:edit $FORJ_HPC "$REF=$VALUE"
      fi
   REFS="$REFS '$REF'"
   fi
   let iCount++
 done
 Info "Found definitions :$REFS"
 if [ "$HPC_COPY" != "True" ] && [ -r ~/.hpcloud/accounts/.cache/$FORJ_HPC ]
 then
    echo "Cleaning '$FORJ_HPC' hpcloud cache."
    rm -f ~/.hpcloud/accounts/.cache/$FORJ_HPC
 fi
}


