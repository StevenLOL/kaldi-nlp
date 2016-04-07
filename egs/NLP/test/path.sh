export KALDI_ROOT=../../../
export PATH=$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PATH
[ ! -f $KALDI_ROOT/src/path.sh ] && echo >&2 "The standard file $KALDI_ROOT/src/path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/src/path.sh
export LC_ALL=C
