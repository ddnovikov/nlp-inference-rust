#!/bin/bash

set -e
MODELS_DIR='/models'

if [ -d "$MODELS_DIR" ]
then
    echo 'cloning repos...'
    git clone https://huggingface.co/cardiffnlp/twitter-xlm-roberta-base-sentiment /models/twitter-xlm-roberta-base-sentiment
    git clone https://huggingface.co/ivanlau/language-detection-fine-tuned-on-xlm-roberta-base /models/language-detection-fine-tuned-on-xlm-roberta-base
    cd /models/language-detection-fine-tuned-on-xlm-roberta-base
    tmp=$(mktemp) && jq --arg skipLibCheck true ' .label2id |= with_entries(.value |= tonumber) ' config.json > "$tmp" && mv "$tmp" config.json
    git clone https://huggingface.co/svalabs/twitter-xlm-roberta-crypto-spam /models/twitter-xlm-roberta-crypto-spam
    git clone https://huggingface.co/EIStakovskii/xlm_roberta_base_multilingual_toxicity_classifier_plus /models/xlm_roberta_base_multilingual_toxicity_classifier_plus
    cd /models/xlm_roberta_base_multilingual_toxicity_classifier_plus
    tmp=$(mktemp) && jq --arg skipLibCheck true '. += { id2label : { "0": "LABEL_0", "1": "LABEL_1" } }' config.json > "$tmp" && mv "$tmp" config.json
    git clone https://huggingface.co/jy46604790/Fake-News-Bert-Detect /models/Fake-News-Bert-Detect
    cd /models/Fake-News-Bert-Detect
    tmp=$(mktemp) && jq --arg skipLibCheck true '. += { id2label : { "0": "LABEL_0", "1": "LABEL_1" } }' config.json > "$tmp" && mv "$tmp" config.json
    cd
    echo 'done'

    echo 'converting models to rust-bert compatible format'
    model_files=(
        "/models/twitter-xlm-roberta-base-sentiment/pytorch_model.bin"
        "/models/language-detection-fine-tuned-on-xlm-roberta-base/pytorch_model.bin"
        "/models/twitter-xlm-roberta-crypto-spam/pytorch_model.bin"
        "/models/xlm_roberta_base_multilingual_toxicity_classifier_plus/pytorch_model.bin"
        "/models/Fake-News-Bert-Detect/pytorch_model.bin"
    )
    
    for file_path in "${model_files[@]}"
    do
        python3 /usr/src/infra-challenge/convert_model.py "$file_path"
        rm "$file_path"
    done
else
	echo "directory $MODELS_DIR is not mounted, exiting"
    exit
fi

echo 'all done, starting the server'

infra-challenge