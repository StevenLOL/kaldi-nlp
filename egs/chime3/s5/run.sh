#!/bin/bash

# Kaldi ASR baseline for the 3rd CHiME Challenge
#
# Copyright 2015 University of Sheffield (Jon Barker, Ricard Marxer)
#                Inria (Emmanuel Vincent)
#                Mitsubishi Electric Research Labs (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh
. ./cmd.sh

# Config:
stage=0 # resume training with --stage=N

. utils/parse_options.sh || exit 1;

# check BeamformIt, IRSTLM, SRILM, and RNNLM are installed or not
if [ -z $BEAMFORMIT ] ; then
  export BEAMFORMIT=$KALDI_ROOT/tools/BeamformIt-3.51
fi
export PATH=${PATH}:$BEAMFORMIT
! hash BeamformIt && echo "Missing BeamformIt, run 'cd ../../../tools/; make beamformit;'" && exit 1
if [ -z $IRSTLM ] ; then
  export IRSTLM=$KALDI_ROOT/tools/irstlm/
fi
export PATH=${PATH}:$IRSTLM/bin
if ! command -v prune-lm >/dev/null 2>&1 ; then
  echo "$0: Error: the IRSTLM is not available or compiled" >&2
  echo "$0: Error: We used to install it by default, but." >&2
  echo "$0: Error: this is no longer the case." >&2
  echo "$0: Error: To install it, go to $KALDI_ROOT/tools" >&2
  echo "$0: Error: and run extras/install_irstlm.sh" >&2
  exit 1
fi
if [ -z $SRILM ] ; then
  export SRILM=$KALDI_ROOT/tools/srilm/
fi
export PATH=${PATH}:$SRILM/bin/i686-m64
! hash ngram-count && echo "Missing srilm, run 'cd ../../../tools/; extras/install_srilm.sh;'" && exit 1

if [ -z $RNNLM ] ; then
  export RNNLM=$KALDI_ROOT/tools/rnnlm-0.3e
fi
export PATH=${PATH}:$RNNLM
! hash rnnlm && echo "Missing rnnlm, run 'cd ../../../tools/; extras/install_mikolov_rnnlm.sh rnnlm-0.3e;'" && exit 1

# You can execute run_init.sh only "once"
# This creates LMs, basic task files, basic models,
# baseline results without speech enhancement techniques, and so on.
# Please set a main root directory of the CHiME3 data
# If you use kaldi scripts distributed in the CHiME3 data,
# chime3_data=`pwd`/../..
# Otherwise, please specify it, e.g.,
chime3_data=/data2/archive/speech-db/original/public/CHiME3
if [ ! -d $chime3_data ]; then
  echo "$chime3_data does not exist. Please specify chime3 data root correctly" && exit 1
fi
if [ $stage -le 0 ]; then
  local/run_init.sh $chime3_data
fi

# Using Beamformit
# This results in better performance than the CHiME3 official beamforming
# See Hori et al, "The MERL/SRI system for the 3rd CHiME challenge using beamforming,
# robust feature extraction, and advanced speech recognition," in Proc. ASRU'15
# note that beamformed wav files are generated in the following directory
enhancement_method=beamformit_5mics
enhancement_data=`pwd`/$enhancement_method
if [ $stage -le 1 ]; then
  local/chime3_beamform.sh --cmd "$train_cmd" --nj 20 $chime3_data/data/audio/16kHz/isolated $enhancement_data
fi

# GMM based ASR experiment
# Please set a directory of your speech enhancement method.
# run_gmm.sh can be done every time when you change a speech enhancement technique.
# The directory structure and audio files must follow the attached baseline enhancement directory
# if you want to use the CHiME3 official enhanced data, please comment out the following
# enhancement_method=enhanced
# enhancement_data=$chime3_data/data/audio/16kHz/enhanced
if [ $stage -le 2 ]; then
  local/run_gmm.sh $enhancement_method $enhancement_data
fi

# DNN based ASR experiment
# Since it takes time to evaluate DNN, we make the GMM and DNN scripts separately.
# You may execute it after you would have promising results using GMM-based ASR experiments
if [ $stage -le 3 ]; then
  local/run_dnn.sh $enhancement_method $enhancement_data
fi

# LM-rescoring experiment with 5-gram and RNN LMs
# It takes a few days to train a RNNLM.
if [ $stage -le 4 ]; then
  local/run_lmrescore.sh $chime3_data $enhancement_method
fi

echo "Done."
