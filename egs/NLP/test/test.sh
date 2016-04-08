# test.sh

# Copyright 2009-2016 (author: Steven Du)

# See ../../COPYING for clarification regarding multiple authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http:#www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.
# REF  copy-feats.cc compute-cmvn-stats.cc
#



. path.sh

###############Functional testing####################

delta_opts="--delta-window=3 --delta-order=2"
all_feats="ark,s,cs:add-deltas $delta_opts ark:./test.ark ark:- |"
add-deltas $delta_opts ark:./test.ark ark,t: > output_add_delta.ark
feat-to-dim ark:./output_add_delta.ark ark,t:- 
feat-to-len ark:./output_add_delta.ark ark,t:-

copy-feats ark:./test.ark ark:- | add-deltas $delta_opts ark:- ark,t: > output_add_delta_copy_feats.ark
feat-to-dim ark:./output_add_delta_copy_feats.ark ark,t:- 
feat-to-len ark:./output_add_delta_copy_feats.ark ark,t:-


embed-feats --w2vdim=20 ark:./dict.ark ark:./test-embed.ark ark:- | add-deltas $delta_opts ark:- ark,t: > output_add_delta_embed_feats.ark
feat-to-dim ark:./output_add_delta_embed_feats.ark ark,t:- 
feat-to-len ark:./output_add_delta_embed_feats.ark ark,t:-
feat-to-dim ark:dict.ark ark,t: 

#All files gives same output

#############TEST SPEED################################
#test w2v and load dict as ark or scp
#load a large ark will no doubt slower than load an scp
#./w2v.en.20.ark    		Google word2vector 20 dim 30M words, in raw text format  (640MB)
#./w2v.en.20.kaldi.ark 	Google word2vector 20 dim 30M words, in binary format    (314MB)
#./w2v.en20.kaldi.scp   scp file of above ark file                               (131MB)
copy-vector ark:./w2v.en.20.ark ark,scp:./w2v.en.20.kaldi.ark,w2v.en20.kaldi.scp

##slow## 40s
time embed-feats --w2vdim=20 ark:./w2v.en.20.ark ark:./free_text.txt ark,t:-
time embed-feats --w2vdim=20 ark:./w2v.en.20.ark ark:./free_text_10x.txt ark,t:-
##faster## 10s
time embed-feats --w2vdim=20 scp:./w2v.en.20.kaldi.scp ark:./free_text.txt ark,t:-
time embed-feats --w2vdim=20 scp:./w2v.en.20.kaldi.scp ark:./free_text_10x.txt ark,t:-
##faster+## 7s
time embed-feats --w2vdim=20 ark:./w2v.en.20.kaldi.ark ark:./free_text.txt ark,t:-
time embed-feats --w2vdim=20 ark:./w2v.en.20.kaldi.ark ark:./free_text_10x.txt ark,t:-

