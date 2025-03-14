tmpcd() {
	if [ -n "$1" ] ; then
		mkdir /tmp/$1
		cd /tmp/$1
	else
		cd $(mktemp -d /tmp/ese_XXXXXX)
	fi
}

mkcd() {
	mkdir $1
	cd $1
}
