source_tirrex() {
  unset ROS_DISTRO
  source /usr/share/gazebo/setup.sh
  source /opt/ros/galactic/setup.zsh
  source ~/projects/ros/tirrex_ws/install/local_setup.zsh
  source /usr/share/colcon_cd/function/colcon_cd.sh
  eval "$(register-python-argcomplete3 ros2)"
  eval "$(register-python-argcomplete3 colcon)"
  export RCUTILS_COLORIZED_OUTPUT=1
  export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}] {name}: {message}"
	export GAZEBO_RESOURCE_PATH="$GAZEBO_RESOURCE_PATH:$HOME/data/romea/gazebo"
	export GAZEBO_MODEL_PATH="$GAZEBO_MODEL_PATH:$HOME/data/romea/gazebo/models"
}

src_ros() {
  source /opt/ros/jazzy/setup.zsh
  export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
  eval "$(register-python-argcomplete ros2)"
  eval "$(register-python-argcomplete colcon)"
}  

alias ccd="colcon_cd"
alias ccb="colcon build --symlink-install"
