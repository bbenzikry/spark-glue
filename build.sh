#!/bin/bash
set -ex
git clone https://github.com/apache/spark.git spark_clone
cd spark_clone
#shellcheck disable=SC2154
git checkout "tags/v${SPARK_VERSION}" -b "v${SPARK_VERSION}"
./dev/make-distribution.sh --name spark-patched --pip -Pkubernetes -Phive -Phive-thriftserver -Phadoop-provided -Dhadoop.version="${HADOOP_VERSION}"
find /catalog -name "*.jar" | grep -Ev "test|original" | xargs -I{} cp {} ./dist/jars
DIRNAME=spark-${SPARK_VERSION}-bin-hadoop-provided-glue
echo "Uploading to DIRNAME $DIRNAME"
mv /mnt/ramdisk/spark_clone/dist "/$DIRNAME"
cd /
echo "Creating archive $DIRNAME.tgz"
tar -cvzf "$DIRNAME.tgz" "$DIRNAME"



