# MODIFIED BY RSPACE DOCKER INSTALL TEAM
# Script looking for a Java runtime suitable for running Tomcat
#
# The script looks for the default JRE/JDK, OpenJDK and Oracle JDK
# as packaged by java-package. The Java runtime found is exported
# in the JAVA_HOME environment variable.
#

set -e

# Find the Java runtime if JAVA_HOME isn't already defined
if [ -z "$JAVA_HOME" ]; then
    # This function sets the variable JDK_DIRS
    find_jdks()
    {
        for java_version in 17 11 10 9 8
        do
            for jvmdir in /usr/lib/jvm/java-${java_version}-openjdk-* \
                          /usr/lib/jvm/jdk-${java_version}-oracle-* \
                          /usr/lib/jvm/jre-${java_version}-oracle-* \
                          /usr/lib/jvm/java-${java_version}-oracle \
                          /usr/lib/jvm/oracle-java${java_version}-jdk-* \
                          /usr/lib/jvm/oracle-java${java_version}-jre-*
            do
                if [ -d "${jvmdir}" ]
                then
                    JDK_DIRS="${JDK_DIRS} ${jvmdir}"
                fi
            done
        done
    }

    # The first existing directory is used for JAVA_HOME
    JDK_DIRS="/usr/lib/jvm/default-java"
    find_jdks

    # Look for the right JVM to use
    for jdir in $JDK_DIRS; do
        if [ -r "$jdir/bin/java" -a -z "${JAVA_HOME}" ]; then
            JAVA_HOME="$jdir"
        fi
    done
fi

if [ -z "$JAVA_HOME" ]; then
    echo "<2>No JDK or JRE found - Please set the JAVA_HOME variable or install the default-jdk package"
    exit 1
fi

export JAVA_HOME
