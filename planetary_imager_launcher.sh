#!/bin/bash
current_dir="$( cd "$( dirname "$0" )" && pwd )"
bundle_dir="$( cd "$current_dir/.." && pwd )"
"$current_dir"/planetary_imager --drivers "$bundle_dir/Drivers" "$@"
