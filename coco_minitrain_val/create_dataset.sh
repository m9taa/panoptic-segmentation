#!/usr/bin/env bash

SCRIPTS_DIR=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "${SCRIPTS_DIR}"/setup.sh

mkdir -p "${ANNOTATIONS_DIR}"

# Download annotations
echo "Downloading annotations..."

ANNOTATIONS=("annotations_trainval2017" "panoptic_annotations_trainval2017")

for anno in ${ANNOTATIONS[@]}; do
    wget "http://images.cocodataset.org/annotations/${anno}.zip" -O "${DATA_DIR}/${anno}.zip"
    unzip -u -d "${DATA_DIR}" "${DATA_DIR}/${anno}.zip" > /dev/null
    rm "${DATA_DIR}/${anno}.zip"
done

ANNOTATIONS=("panoptic_train2017" "panoptic_val2017")

for anno in ${ANNOTATIONS[@]}; do
    unzip -u -d "${DATA_DIR}" "${ANNOTATIONS_DIR}/${anno}.zip" > /dev/null
    rm "${ANNOTATIONS_DIR}/${anno}.zip"
done

# Download images
echo "Downloading images..."

IMAGES=("train2017" "val2017")

for set_name in ${IMAGES[@]}; do
    wget "http://images.cocodataset.org/zips/${set_name}.zip" -O "${DATA_DIR}/${set_name}.zip"
    unzip -u -d "${DATA_DIR}" "${DATA_DIR}/${set_name}.zip" > /dev/null
    rm "${DATA_DIR}/${set_name}.zip"
done

# Download coco-minitrain annot json from gdrive
gdown --id 1lezhgY4M_Ag13w0dEzQ7x_zQ_w0ohjin

# Make a subset of orig coco annots with minitrain samples ids
mv "instances_minitrain2017.json" "${ANNOTATIONS_DIR}/instances_train2017.json"

# Make a subset of panoptic coco annots with minitrain samples ids
python "${SCRIPTS_DIR}"/make_coco_subset.py \
    --minitrain_annotation_file "${ANNOTATIONS_DIR}/instances_train2017.json"\
    --target_annotation_file "${ANNOTATIONS_DIR}/panoptic_train2017.json" \
    --target_images_dir "${DATA_DIR}/panoptic_train2017" \
    --replace true

# Make a subset of orig coco images with minitrain samples ids
python "${SCRIPTS_DIR}"/make_coco_subset.py \
    --minitrain_annotation_file "${ANNOTATIONS_DIR}/instances_train2017.json" \
    --target_images_dir "${DATA_DIR}/train2017" \

# Generate stuff segmentation annotation with detectron
pip install git+https://github.com/cocodataset/panopticapi.git
git clone https://github.com/facebookresearch/detectron2.git
python -m pip install -e detectron2

DETECTRON2_DATASETS=$(pwd) python detectron2/datasets/prepare_panoptic_fpn.py
