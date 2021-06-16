<!-- Taken from https://gitlab.com/inkscape/inkscape/-/issues/791#note_584055227 -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[local-name()='clipPath']/@transform"/>
</xsl:stylesheet>
