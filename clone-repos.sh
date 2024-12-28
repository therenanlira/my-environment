#!/bin/zsh

repositories=(
  "acc--infra"
  "acd--infra"
  "acd--platform"
  "ads--infra"
  "backoffice--infra"
  "bill--infra"
  "cs2--infra"
  "dev--local-env"
  "devops--amis"
  "devops--docker-images"
  "devops--pulumi-packages"
  "devops--templates-pipelines"
  "devops--terraform-modules"
  "dmp--infra"
  "dsp--infra"
  "dts--infra"
  "frontoffice--infra"
  "iam--infra"
  "infra--dev-tools"
  "infra--shared--environments"
  "infra--shared--ops"
  "infra--shared--ops-pulumi"
  "infra--shared--pulumi-state"
  "infra--shared--regional"
  "infra--shared--regional-pulumi"
  "infra--shared--remote-state"
  "int--infra"
  "med--infra"
  "mon--infra"
  "onb--infra"
  "opsec--credential-rotator--infra"
  "rtb--infra"
  "tag--infra"
  "trx--infra"
)

for repo in ${repositories[@]}; do
  git clone git@ssh.dev.azure.com:v3/blue-media-services/BMS/$repo
done
