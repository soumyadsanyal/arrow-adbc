#!/usr/bin/env bash
# -*- indent-tabs-mode: nil; sh-indentation: 2; sh-basic-offset: 2 -*-
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

set -e
set -u
set -o pipefail

main() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit
  fi

  local -r version="$1"
  local -r tag="apache-arrow-adbc-${version}"

  if [ -z "${NUGET_API_KEY}" ]; then
    echo "NUGET_API_KEY is empty"
    exit 1
  fi

  : ${REPOSITORY:="apache/arrow-adbc"}

  local -r tmp=$(mktemp -d -t "arrow-post-csharp.XXXXX")

  header "Downloading C# packages for ${version}"

  gh release download \
     --repo "${REPOSITORY}" \
     "${tag}" \
     --dir "${tmp}" \
     --pattern "*.nupkg" \
     --pattern "*.snupkg"

  local base_names=()
  base_names+=(Apache.Arrow.Adbc.${version})
  base_names+=(Apache.Arrow.Adbc.Client.${version})
  base_names+=(Apache.Arrow.Adbc.Drivers.BigQuery.${version})
  base_names+=(Apache.Arrow.Adbc.Drivers.FlightSql.${version})
  base_names+=(Apache.Arrow.Adbc.Drivers.Interop.Snowflake.${version})
  for base_name in "${base_names[@]}"; do
    dotnet nuget push \
      "${tmp}/${base_name}.nupkg" \
      -k ${NUGET_API_KEY} \
      -s https://api.nuget.org/v3/index.json
  done

  rm -rf "${tmp}"

  echo "Success! The released NuGet package is available here:"
  echo "  https://www.nuget.org/packages/Apache.Arrow.Adbc/${version}"
}

header() {
    echo "============================================================"
    echo "${1}"
    echo "============================================================"
}

main "$@"
