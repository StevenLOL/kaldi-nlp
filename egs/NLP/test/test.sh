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