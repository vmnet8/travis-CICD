#!/bin/bash

#set -x

get_manifest_sha(){
    local sha
    docker_repo=$1  #alpine or vmnet/alpine
    manifest_tag=$2
    docker_image=$docker_repo:$manifest_tag
    arch=$3
    variant=$4
    export DOCKER_CLI_EXPERIMENTAL=enabled

    docker pull -q  ${docker_image} &>/dev/null
    docker manifest inspect ${docker_image} > "$2".txt

    sha=""
    i=0
    while [ "$sha" == "" ] && read -r line
    do
        arch=$(jq .manifests[$i].platform.architecture "$2".txt |sed -e 's/^"//' -e 's/"$//')
        if [ "$arch" = "$3" ] && [ "$arch" !=  "arm" ]; then
            sha=$(jq .manifests[$i].digest "$2".txt  |sed -e 's/^"//' -e 's/"$//')
            echo ${sha}
        elif [ "$arch" = "$3" ]; then
            variant=$(jq .manifests[$i].platform.variant "$2".txt |sed -e 's/^"//' -e 's/"$//')
            if [ "$variant" == "$4" ]; then
                sha=$(jq .manifests[$i].digest "$2".txt  |sed -e 's/^"//' -e 's/"$//')
             #   echo ${sha}
            fi
        fi
        i=$i+1
    done < "$2".txt
}

get_tag_sha(){
    #docker_image=$1
    local repo=$1
    local tag=$2
    docker pull "$repo:$tag" &>/dev/null
    #sha=$(docker inspect --format='{{index .RepoDigests 0}}' balenalib/raspberry-pi-alpine:run | cut -d @ -f 2)
    sha=$(docker inspect --format='{{index .RepoDigests 0}}' "$repo:$tag" 2>/dev/null | cut -d @ -f 2)
    #docker inspect --format='{{index .RepoDigests 0}}' "$repo:$tag" 2>/dev/null | cut -d @ -f 2
    echo $sha
}


compare_sha () {
    if [ "$1" != "$2" ] || [ "$3" != "$4" ]; then
        #echo $?
        echo "true"
    else
        #echo "no need do nothing"
        #echo $?
        echo "false"
    fi
}

manifest_sha () {
    if ! compare_sha "$1" "$2" || ! compare_sha "$3" "$4" ; then
        create_manifest
    else
        echo "no need to create new manifest"
    fi
}

create_manifest(){
    echo "will create manifest"
    local alpine_tag=$1
    local balena_tag=$2
    local my_alpine_tag=$3
    alpine_sha=$(get_manifest_sha $ALPINE_REPO $1 "amd64")
#    echo $alpine_sha
 #   timetag="$(date +%Y%m%d%H%M)"
    docker pull $ALPINE_REPO:$alpine_tag
    docker pull $BALENA_REPO:$balena_tag
    #docker tag $ALPINE_REPO:$tag  $MY_RPI_REPO:"x86"-$alpine_tag
    #docker tag $BALENA_REPO:$balena_tag  $MY_RPI_REPO:"rpi"-$balena_tag
    #docker push $MY_RPI_REPO:"x86"-$alpine_tag
    #docker push $MY_RPI_REPO:"rpi"-$balena_tag
    #docker push vmnet8/alpine-tags:$arch-$my_tag-$timetag
    echo "create new manifest"
    a=$ALPINE_REPO"@"$alpine_sha
    #echo $a
    #docker manifest create $MY_ALPINE_REPO:$my_alpine_tag-$timetag $ALPINE_REPO"@"$alpine_sha $BALENA_REPO:$balena_tag
    docker manifest create $MY_ALPINE_REPO:$my_alpine_tag $ALPINE_REPO"@"$alpine_sha $BALENA_REPO:$balena_tag
    #docker manifest push $MY_ALPINE_REPO:$my_alpine_tag
}
push_manifest(){
    local my_alpine_tag=$1
    export DOCKER_CLI_EXPERIMENTAL=enabled
    echo "push manifest"
    docker manifest push $MY_ALPINE_REPO:$my_alpine_tag
}

flag (){
    flag=$(compare_sha $1 $2 $3 $4)
    if [ $flag -eq 0 ]; then
        return
    fi
}

ALPINE_REPO='alpine'
MY_ALPINE_REPO='vmnet8/alpine'
MY_RPI_REPO='vmnet8/alpine-tags'
BALENA_REPO='balenalib/raspberry-pi-alpine'
timetag="$(date +%Y%m%d%H%M)"

compare_alpine() {
    local tag=$1
    local arch=$2
    alpine_sha=$(get_manifest_sha $ALPINE_REPO $tag $arch)
 #   echo $alpine_sha
    my_alpine_sha=$(get_manifest_sha $MY_ALPINE_REPO $tag $arch)
 #   echo $my_alpine_sha
    if [ "$alpine_sha" != "$my_alpine_sha" ]; then
        #create_manifest("3.12.0" "20200518" "test")
        return_value=$?
        echo $return_value
      #  push_manifest
    fi
    #if [ "$arch" = arm ]; then
    #    balena_rpi_sha=$(get_tag_sha $BALENA_REPO $tag)
    #    echo $balena_rpi_sha
    #    my_rpi_sha=$(get_tag_sha $MY_RPI_REPO $tag)
    #    echo $my_rpi_sha
    #    if [ "$belena_rpi_sha" != "$my_rpi_sha" ]; then
    #        create_manifest
    #    fi
    #fi
}

compare_balena() {
    local balena_tag=$1
    local my_tag=$2
    balena_rpi_sha=$(get_tag_sha $BALENA_REPO $1)
 #   echo $balena_rpi_sha
    my_rpi_sha=$(get_tag_sha $MY_RPI_REPO $2)
  #  echo $my_rpi_sha
    if [ "$belena_rpi_sha" != "$my_rpi_sha" ]; then
        #create_manifest
        echo   "create_manifest"
#        push_manifest
    fi
}

#a=$(compare_sha $1 $2 $3 $4)
#echo "a is: $a"

#compare_sha $1 $2 $3 $4
#compare_alpine $@
#compare_balena $@
#get_manifest_sha "vmnet8/alpine:$manifest_tag" "$arch"
#get_manifest_sha $@
#get_vmnet_sha $1 $2
#get_tag_sha $1 $2
#create_manifest $@
push_manifest $1
#manifest_sha $1 $2 $3 $4
