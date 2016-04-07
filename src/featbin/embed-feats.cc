// featbin/copy-feats.cc

// Copyright 2009-2011  Microsoft Corporation
//                2013  Johns Hopkins University (author: Daniel Povey)

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
#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "matrix/kaldi-matrix.h"


int main(int argc, char *argv[]) {
  try {
    using namespace kaldi;

    const char *usage =
        "Copy features [and possibly change format]\n"
        "Usage: copy-feats [options] <w2v-dict-rspecifier><feature-rspecifier> <feature-wspecifier>\n"
        "e.g.: copy-feats --w2vdim=20 ark:./dict.ark ark:./textfile.ark ark:- \n"
        " or: copy-feats ark:foo.ark ark,t:txt.ark\n"
        "See also: copy-matrix, copy-feats-to-htk, copy-feats-to-sphinx, select-feats,\n"
        "extract-rows, subset-feats, subsample-feats, splice-feats, paste-feats,\n"
        "concat-feats\n";

    ParseOptions po(usage);
    bool binary = true;
    bool htk_in = false;
    bool sphinx_in = false;
    bool compress = false;
    int w2vdim=20;

    po.Register("w2vdim", &w2vdim, "w2vdim for word to vector ");
    /*
    po.Register("sphinx-in", &sphinx_in, "Read input as Sphinx features");
    po.Register("binary", &binary, "Binary-mode output (not relevant if writing "
                "to archive)");
    po.Register("compress", &compress, "If true, write output in compressed form"
                "(only currently supported for wxfilename, i.e. archive/script,"
                "output)");
*/
    po.Read(argc, argv);

    if (po.NumArgs() != 3) {
      po.PrintUsage();
      exit(1);
    }

    int32 num_done = 0;

    if (ClassifyRspecifier(po.GetArg(1), NULL, NULL) != kNoRspecifier) {
      // Copying tables of features.
      std::string rspecifier = po.GetArg(2);
      std::string dictrsecifier = po.GetArg(1);
      std::string wspecifier = po.GetArg(3);

      if (!compress) {
        BaseFloatMatrixWriter kaldi_writer(wspecifier);
        if (htk_in) {
          SequentialTableReader<HtkMatrixHolder> htk_reader(rspecifier);
          for (; !htk_reader.Done(); htk_reader.Next(), num_done++)
            kaldi_writer.Write(htk_reader.Key(), htk_reader.Value().first);
        } else if (sphinx_in) {
          SequentialTableReader<SphinxMatrixHolder<> > sphinx_reader(rspecifier);
          for (; !sphinx_reader.Done(); sphinx_reader.Next(), num_done++)
            kaldi_writer.Write(sphinx_reader.Key(), sphinx_reader.Value());
        } else {
          //SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
        	SequentialTokenVectorReader kaldi_reader(rspecifier); //ref compute-cmvn-stats.cc
        	RandomAccessBaseFloatVectorReader feat_reader(dictrsecifier);

          for (; !kaldi_reader.Done(); kaldi_reader.Next(), num_done++)
		{
              std::string key = kaldi_reader.Key();
              const std::vector<std::string> &uttlist = kaldi_reader.Value();
              Matrix<BaseFloat> new_feats(uttlist.size(),w2vdim);  //ref add-deltas.cc   //new feature for each key
              //std::cout<<key;
              for (size_t i = 0; i < uttlist.size(); i++) {
                 std::string word = uttlist[i];
                 if (!feat_reader.HasKey(word)) {
                   KALDI_WARN << "Did not find features for word: " << word;

                   //num_err++;
                   //continue;
                 }else{
                	 //std::cout<<utt<<feat_reader.Value(utt)<<"\n";
                	 const Vector<BaseFloat> &valuelist=feat_reader.Value(word);
                	 //SubVector<BaseFloat> bfloat(valuelist);
                	 //new_feats.AddVecToRows(1.0,bfloat);
                	 SubVector<float> rowdata=new_feats.Row(MatrixIndexT(i));
                	 rowdata.CopyFromVec(valuelist);
                	/*
                	 for (MatrixIndexT j=0; j< new_feats.NumCols();j++){
                		 rowdata[j]=bfloat(j);
                		 //new_feats.CopyRowsFromVec(valuelist); //=1.0;
                	 }
                	 */
                 }
              }
              kaldi_writer.Write(key, new_feats);
        	 // KALDI_LOG<<kaldi_reader.Key()<<kaldi_reader.Value();
//change embeded matrix value here
//kaldi_writer.Write(kaldi_reader.Key(), kaldi_reader.Value());
		}
        }
      } else {
        CompressedMatrixWriter kaldi_writer(wspecifier);
        if (htk_in) {
          SequentialTableReader<HtkMatrixHolder> htk_reader(rspecifier);
          for (; !htk_reader.Done(); htk_reader.Next(), num_done++)
            kaldi_writer.Write(htk_reader.Key(),
                               CompressedMatrix(htk_reader.Value().first));
        } else if (sphinx_in) {
          SequentialTableReader<SphinxMatrixHolder<> > sphinx_reader(rspecifier);
          for (; !sphinx_reader.Done(); sphinx_reader.Next(), num_done++)
            kaldi_writer.Write(sphinx_reader.Key(),
                               CompressedMatrix(sphinx_reader.Value()));
        } else {
          SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
          for (; !kaldi_reader.Done(); kaldi_reader.Next(), num_done++)
            kaldi_writer.Write(kaldi_reader.Key(),
                               CompressedMatrix(kaldi_reader.Value()));
        }
      }
      KALDI_LOG << "Copied " << num_done << " feature matrices.";
      return (num_done != 0 ? 0 : 1);
    } else {
      KALDI_ASSERT(!compress && "Compression not yet supported for single files");

      std::string feat_rxfilename = po.GetArg(1), feat_wxfilename = po.GetArg(2);

      Matrix<BaseFloat> feat_matrix;
      if (htk_in) {
        Input ki(feat_rxfilename); // Doesn't look for read binary header \0B, because
        // no bool* pointer supplied.
        HtkHeader header; // we discard this info.
        ReadHtk(ki.Stream(), &feat_matrix, &header);
      } else if (sphinx_in) {
        KALDI_ERR << "For single files, sphinx input is not yet supported.";
      } else {
        ReadKaldiObject(feat_rxfilename, &feat_matrix);
      }
      WriteKaldiObject(feat_matrix, feat_wxfilename, binary);
      KALDI_LOG << "Copied features from " << PrintableRxfilename(feat_rxfilename)
                << " to " << PrintableWxfilename(feat_wxfilename);
    }
  } catch(const std::exception &e) {
    std::cerr << e.what();
    return -1;
  }
}


