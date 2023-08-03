DESTINATION_DIR=${DESTINATION_DIR:-$PWD}
MODULE_DIR=${MODULE_DIR:-$PWD}
ZIPFILE_NAME=${ZIPFILE_NAME:-layer}
REQUIREMENTS_FILE_PATH=$MODULE_DIR/requirements.txt
TARGET_DIR=$DESTINATION_DIR/$ZIPFILE_NAME
ZIP_PATH="$DESTINATION_DIR"/"$ZIPFILE_NAME".zip

echo "MODULE_DIR $MODULE_DIR"
echo "TARGET_DIR $TARGET_DIR"
echo "DESTINATION_DIR $DESTINATION_DIR"
echo "ZIPFILE_NAME $ZIPFILE_NAME"
echo "REQUIREMENTS_FILE_PATH $REQUIREMENTS_FILE_PATH"
echo "ZIP_PATH $ZIP_PATH"

mkdir -p "$TARGET_DIR"

rm -f $ZIP_PATH

pip install -r "$REQUIREMENTS_FILE_PATH" -t "$TARGET_DIR"/python

(cd "$TARGET_DIR" && zip -r "$ZIP_PATH" ./* -x "*.dist-info*" -x "*__pycache__*" -x "*.egg-info*")
rm -r "$TARGET_DIR"
