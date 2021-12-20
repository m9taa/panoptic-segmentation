import glob
import json
import os
from typing import Any, Dict, Set


def _extract_ids(minitrain_annotation: Dict[str, Any]) -> Set[int]:
    ids = set()
    for image in minitrain_annotation['images']:
        ids.add(image['id'])
    return ids


def _filter_annotation(panoptic_annotation: Dict[str, Any], ids: Set[int]) -> Dict[str, Any]:
    images = list(filter(lambda image: image['id'] in ids, panoptic_annotation['images']))
    annotations = list(filter(lambda annot: annot['image_id'] in ids, panoptic_annotation['annotations']))
    panoptic_annotation['images'] = images
    panoptic_annotation['annotations'] = annotations
    return panoptic_annotation


def _filter_images(images_dir: str, ids: Set[int]):
    if images_dir and os.path.isdir(images_dir):
        for filepath in glob.glob(os.path.join(images_dir, '*')):
            filename = filepath.split('/')[-1]
            file_basename = os.path.splitext(filename)[0]
            if file_basename.isnumeric() and int(file_basename) not in ids:
                os.remove(filepath)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--minitrain_annotation_file',
        type=str,
        required=True,
        help="Path to the minitrain instances json file, in COCO's format",
    )
    parser.add_argument(
        '--target_annotation_file',
        type=str,
        default=None,
        help="Path to the target annotation file, in COCO's format.",
    )
    parser.add_argument(
        '--target_images_dir',
        type=str,
        default=None,
        help='Path to the target images directory.',
    )
    parser.add_argument(
        '--replace',
        type=bool,
        default=False,
        help="Overwrite the panoptic annotation file with filtered one, in COCO's format.",
    )
    args = parser.parse_args()

    with open(args.minitrain_annotation_file) as fd:
        minitrain_annotation = json.load(fd)
        ids_subset = _extract_ids(minitrain_annotation)

    if args.target_annotation_file:
        with open(args.target_annotation_file) as fd:
            panoptic_annotation = json.load(fd)
        filtered_annotation = _filter_annotation(panoptic_annotation, ids_subset)
        output_anotation_file = args.target_annotation_file
        if not args.replace:
            output_file_path = output_anotation_file.split('/')
            output_file_path[-1] = 'filtered_' + output_file_path[-1]
            output_anotation_file = '/'.join(output_file_path)
        
        with open(output_anotation_file, 'w') as fd:
            json.dump(filtered_annotation, fd, ensure_ascii=False)

    if args.target_images_dir:
        _filter_images(args.target_images_dir, ids_subset)
