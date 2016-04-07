// test.sh

// Copyright 2009-2016 (author: Steven Du)

// See ../../COPYING for clarification regarding multiple authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.
// REF  copy-feats.cc compute-cmvn-stats.cc
//



. path.sh
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