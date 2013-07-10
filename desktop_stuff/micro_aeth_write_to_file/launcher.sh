#!/bin/bash
gnome-terminal --working-directory=WORK_DIR -x bash -c "source ~/.bash_profile; /home/pi/Projects/CombustionEmissionsTesting/write_to_file_micro_aeth.rb; bash"
