class ApiConstants {
  static const ensembl     = 'https://rest.ensembl.org';
  static const grch37      = 'https://grch37.rest.ensembl.org';
  static const uniprot     = 'https://rest.uniprot.org/uniprotkb';
  static const alphafold   = 'https://alphafold.ebi.ac.uk';
  static const interpro    = 'https://www.ebi.ac.uk/interpro/api';
  static const kegg        = 'https://rest.kegg.jp';
  static const stringDb    = 'https://string-db.org/api/json';
  static const quickgo     = 'https://www.ebi.ac.uk/QuickGO/services';
  static const gtex        = 'https://gtexportal.org/rest/v1';
  static const dgidb       = 'https://dgidb.org/api/v2';
  static const chembl      = 'https://www.ebi.ac.uk/chembl/api/data';
  static const clinTrials  = 'https://clinicaltrials.gov/api/v2';
  static const ucsc        = 'https://api.genome.ucsc.edu';
  static const pgsCatalog  = 'https://www.pgscatalog.org/rest';
  static const gdc         = 'https://api.gdc.cancer.gov';
  static const fdn         = 'https://data.4dnucleome.org';
  static const jaspar      = 'https://jaspar.elixir.no/api/v1';
  static const gnomad      = 'https://gnomad.broadinstitute.org/api';
  static const encode      = 'https://www.encodeproject.org';
  static const ncbi        = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils';

  static const spliceaiBrowserUrl = 'https://spliceailookup.broadinstitute.org';
  static const horvathWeightsAsset = 'assets/demo_data/horvath_cpg_weights.csv';

  static String alphaFoldPrediction(String uniprotId) =>
    'https://alphafold.ebi.ac.uk/api/prediction/$uniprotId';

  static String ncbiUrl(String endpoint, Map<String, String> params) {
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$ncbi/$endpoint?$query';
  }

  static Map<String, dynamic> gnomadVariantQuery(String variantId) => {
    'query': '''
      query Variant(\$variantId: String!) {
        variant(variantId: \$variantId, dataset: gnomad_r4) {
          variantId chrom pos ref alt
          exome { ac { ac an } }
          genome { ac { ac an } }
        }
      }
    ''',
    'variables': {'variantId': variantId},
  };
}
