<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

 <xsl:template match="/TEI.2">
	<xsl:for-each select="child::text">      
       <xsl:variable name="title-anchor" select="generate-id(.)"/>
       <xsl:call-template name="text">
         <xsl:with-param name="anchor" select="$title-anchor"/>
       </xsl:call-template>
     </xsl:for-each>
 </xsl:template>
  
  <xsl:template name="text">
	
    <xsl:param name="anchor"/>
    <a name="{$anchor}"/>
    <div>
      <xsl:apply-templates/>
      
      <!--
      <xsl:apply-templates select="descendant::head"/>
      <xsl:apply-templates select="descendant::lg"/>
      <xsl:apply-templates select="descendant::note"/>
      <xsl:apply-templates select="descendant::pb"/>
      -->
    </div>
  </xsl:template>
  
  <xsl:template match="head">
    <h3><xsl:apply-templates/></h3>
  </xsl:template>
  
  <xsl:template match="lg">
	<div>
    <xsl:apply-templates/>
</div>
  </xsl:template>
  
  <xsl:template match="note">
    <br/><br/>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="l">
    <xsl:if test="@rend='ti-1'">
      &#160;
    </xsl:if>
    <xsl:if test="@rend='ti-2'">
      &#160; &#160;
    </xsl:if>
    
    <xsl:apply-templates/><br/>
  </xsl:template>
  
  <xsl:template match="pb">
    <center>
      <xsl:value-of select="@n"/><br/>
    </center>
  </xsl:template>
  
  <xsl:template match="hi[@rend='sc']">
    <span style="text-transform: uppercase"><xsl:value-of select="."/></span>
  </xsl:template>
  
  <xsl:template match="hi[@rend='i']">
    <i><xsl:value-of select="."/></i>
  </xsl:template>
  
</xsl:stylesheet>