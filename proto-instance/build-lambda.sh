log=$(mktemp)
ret=0
{
  pushd lambda
    make || ret=$?
  popd
} > $log

if [ "${ret}" != "0" ]; then
  cat $log
  exit $ret
fi

echo "{ \"status\": \"${ret}\" }"
exit 0