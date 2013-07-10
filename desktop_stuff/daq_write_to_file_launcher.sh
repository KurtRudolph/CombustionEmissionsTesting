#!/bin/bash
#lxterminal -e "ruby /home/pi/Projects/CombustionEmissionsTesting/write_to_file_daq.rb"
gnome-terminal --working-directory=WORK_DIR -x bash -c "source ~/.bash_profile; /home/pi/Projects/CombustionEmissionsTesting/write_to_file_daq.rb; bash"
