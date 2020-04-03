#!/usr/bin/env bash

ARTIFACT=spring-batch-native
MAINCLASS=org.springframework.samples.springbatchnative.SpringBatchNativeApplication
VERSION=0.0.1-BUILD-SNAPSHOT
FEATURE=../../../../spring-graal-native/target/spring-graal-native-0.6.0.BUILD-SNAPSHOT.jar

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

rm -rf target
mkdir -p target/native-image

echo "Packaging $ARTIFACT with Maven"
../../mvnw -DskipTests package > target/native-image/output.txt

JAR="$ARTIFACT-$VERSION.jar"
rm -f $ARTIFACT
echo "Unpacking $JAR"
cd target/native-image
jar -xvf ../$JAR >/dev/null 2>&1
cp -R META-INF BOOT-INF/classes

LIBPATH=`find BOOT-INF/lib | tr '\n' ':'`
CP=BOOT-INF/classes:$LIBPATH:$FEATURE

echo "Classpath: $CP"
pwd

GRAALVM_VERSION=`native-image --version`
echo "Compiling $ARTIFACT with $GRAALVM_VERSION"
time native-image \
  --no-server \
  --no-fallback \
  -Dspring.graal.skip-logback=true \
  -Ddebug=true \
  -Dio.netty.noUnsafe=true \
  -H:Name=$ARTIFACT \
  -H:+ReportExceptionStackTraces \
  -H:+TraceClassInitialization \
  --initialize-at-build-time=com.mysql.cj.jdbc.Driver org.springframework.samples.springbatchnative.SpringBatchNativeApplication
  -cp $CP $MAINCLASS >> output.txt


#if [[ -f $ARTIFACT ]]
#then
#  printf "${GREEN}SUCCESS${NC}\n"
#  mv ./$ARTIFACT ..
#  exit 0
#else
#  printf "${RED}FAILURE${NC}: an error occurred when compiling the native-image.\n"
#  exit 1
#fi
#