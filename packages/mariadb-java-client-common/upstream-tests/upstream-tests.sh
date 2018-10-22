#!/bin/bash

dnf install -y mariadb-java-client mariadb-java-client-tests hamcrest junit mariadb-server unzip

# list all available test classes
MARIADB_TESTS="$(unzip -Z1 $JAVA_LIBRARY_TESTS | grep 'Test.class' | cut -d'.' -f1 | tr '/' '.' | sort)"

initialize_db() {
	systemctl start mariadb
	# remove anonymous, because tests fail otherwise
	mysql -e "DROP USER ''@'localhost'"
	mysql -e "DROP USER ''@'$(hostname)'"
	mysql -e "FLUSH PRIVILEGES"
	# create database on which tests operate
	mysql -e "CREATE DATABASE testj"
}

run_test() {
	local JAVA_PATH=.
	# import JUnit
	JAVA_PATH=$JAVA_PATH:/usr/share/java/hamcrest/core.jar
	JAVA_PATH=$JAVA_PATH:/usr/share/java/junit.jar
	# MariaDB
	JAVA_PATH=$JAVA_PATH:$JAVA_LIBRARY:$JAVA_LIBRARY_TESTS
	# other dependencies
	JAVA_PATH=$JAVA_PATH:/usr/share/java/slf4j/slf4j-api.jar
	JAVA_PATH=$JAVA_PATH:/usr/share/java/slf4j/slf4j-simple.jar
	JAVA_PATH=$JAVA_PATH:/usr/share/java/aws-sdk-java/aws-java-sdk-core.jar
	JAVA_PATH=$JAVA_PATH:/usr/share/java/aws-sdk-java/aws-java-sdk-rds.jar
	JAVA_PATH=$JAVA_PATH:/usr/lib/java/jna.jar
	JAVA_PATH=$JAVA_PATH:/usr/share/java/jna/jna-platform.jar
	JAVA_PATH=$JAVA_PATH:/usr/share/java/HikariCP.jar

	java -Xmx1024m -cp $JAVA_PATH org.junit.runner.JUnitCore "$1"
}

run_all() {
	local FAILED=false
	echo "These tests will run: $MARIADB_TESTS"
	while read -r test; do
		echo "Run test: '$test'"
		run_test $test || FAILED=true
	done <<< "$MARIADB_TESTS"
	[ "$FAILED" == "true" ] && {
	echo '*********************************'
	echo '************ TESTS HAVE FAILURES!'
	echo '*********************************'
	return 1
	}
	[ "$FAILED" == "false" ] && {
	echo '**********************************'
	echo '************ TESTS WERE SUCCESSFUL'
	echo '**********************************'
	}
}

initialize_db
run_all


