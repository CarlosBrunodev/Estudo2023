#!/bin/bash

# Esse script deve ser executado na VM Master que realizada o controle do RKE 
# e/ou em outra VM que tenha os mesmo acessos.

# Variables

VAR_RKE_VERSION=""
VAR_RKE_SYSTE_IMAGES=""

# Script
echo " ------------------------------------------------------------"
echo "| Script para download e sincronização das images do Docker  |"
echo " ------------------------------------------------------------"

echo ""
echo "Iniciando checagem de versao..."
echo "Versoes disponiveis:"
rke config --list-version --all

echo ""
read -p  " Informe a versao do RKE:" VAR_RKE_VERSION
echo ""
echo "Versao selecionada $VAR_RKE_VERSION..."


echo "Iniciando Download das Imagems..."

VAR_RKE_SYSTE_IMAGES=$(rke --quiet config --system-images --version $VAR_RKE_VERSION | head -n6 )

echo "          Realizando download as imagens:"
echo "              $VAR_RKE_SYSTE_IMAGES"

#for VAR_IMAGE in $(rke --quiet config --system-images --version $VAR_RKE_VERSION| head -n1); do docker pull $VAR_IMAGE; done
for VAR_IMAGE in $VAR_RKE_SYSTE_IMAGES; do
    echo "                  docker pull $VAR_IMAGE"
    docker pull $VAR_IMAGE
done

echo ""
echo "Iniciando Sincronizacao das Imagens..."


# VAR_VMS=$(cat cluster.yml | grep -i "address:" | awk '{print $3}')

VAR_VMS="172.16.16.101"

for VAR_IMAGE in $VAR_RKE_SYSTE_IMAGES; do
    NEW_IMAGE=$(echo $VAR_IMAGE | awk -F / ' {print $2} ')
    mkdir -p -v /tmp/rke_system_images/$NEW_IMAGE
    cd /tmp/rke_system_images/$NEW_IMAGE
    # NEW_IMAGE=$(echo $VAR_IMAGE | awk -F / ' {print $2} ')
     docker save $VAR_IMAGE  -o  $NEW_IMAGE.tar
done


echo $VAR_RKE_SYSTE_IMAGES > images.txt

for VAR_VM in $VAR_VMS; do
    echo "Realizando sincronizacao e import para $VAR_VM"
    for VAR_IMAGE in `cat images.txt` ; do
        echo $VAR_IMAGE
        NEW_IMAGE=$(echo $VAR_IMAGE | awk -F / ' {print $2} ')
        ssh root@$VAR_VM mkdir -p -v /tmp/rke_system_images/$NEW_IMAGE
        scp -i ~/.ssh/id_ed25519 /tmp/rke_system_images/$NEW_IMAGE/$NEW_IMAGE.tar root@$VAR_VM:/tmp/rke_system_images/$NEW_IMAGE/$NEW_IMAGE.tar
        ssh -i ~/.ssh/id_ed25519 root@$VAR_VM docker load -i /tmp/rke_system_images/$NEW_IMAGE/$NEW_IMAGE.tar
    done
done
