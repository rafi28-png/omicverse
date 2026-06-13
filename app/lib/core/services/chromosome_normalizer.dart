class ChromosomeNormalizer {
  static String ensemblFormat(String chr) =>
    chr.toLowerCase().startsWith('chr') ? chr.substring(3) : chr;

  static String ucscFormat(String chr) =>
    chr.toLowerCase().startsWith('chr') ? chr : 'chr$chr';

  static bool isValid(String chr) {
    final n = ensemblFormat(chr).toUpperCase();
    return ['1','2','3','4','5','6','7','8','9','10','11','12','13',
            '14','15','16','17','18','19','20','21','22','X','Y','MT']
        .contains(n);
  }

  static String fromVcf(String chr) => ensemblFormat(chr.trim());
}
