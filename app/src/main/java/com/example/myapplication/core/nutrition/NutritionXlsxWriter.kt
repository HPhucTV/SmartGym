package com.example.myapplication.core.nutrition

import com.example.myapplication.data.local.FoodCatalogEntity
import java.io.ByteArrayOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

object NutritionXlsxWriter {
    fun write(items: List<FoodCatalogEntity>): ByteArray {
        val bos = ByteArrayOutputStream()
        ZipOutputStream(bos).use { zip ->
            // 1. [Content_Types].xml
            zip.putNextEntry(ZipEntry("[Content_Types].xml"))
            zip.write(getContentTypesXml().toByteArray(Charsets.UTF_8))
            zip.closeEntry()

            // 2. _rels/.rels
            zip.putNextEntry(ZipEntry("_rels/.rels"))
            zip.write(getRelsXml().toByteArray(Charsets.UTF_8))
            zip.closeEntry()

            // 3. xl/workbook.xml
            zip.putNextEntry(ZipEntry("xl/workbook.xml"))
            zip.write(getWorkbookXml().toByteArray(Charsets.UTF_8))
            zip.closeEntry()

            // 4. xl/_rels/workbook.xml.rels
            zip.putNextEntry(ZipEntry("xl/_rels/workbook.xml.rels"))
            zip.write(getWorkbookRelsXml().toByteArray(Charsets.UTF_8))
            zip.closeEntry()

            // 5. xl/worksheets/sheet1.xml
            zip.putNextEntry(ZipEntry("xl/worksheets/sheet1.xml"))
            zip.write(getSheetXml(items).toByteArray(Charsets.UTF_8))
            zip.closeEntry()
        }
        return bos.toByteArray()
    }

    private fun getContentTypesXml(): String {
        return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>"""
    }

    private fun getRelsXml(): String {
        return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>"""
    }

    private fun getWorkbookXml(): String {
        return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>"""
    }

    private fun getWorkbookRelsXml(): String {
        return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>"""
    }

    private fun getSheetXml(items: List<FoodCatalogEntity>): String {
        val sb = java.lang.StringBuilder()
        sb.append("""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
""")

        // Row 1: Headers
        sb.append("""    <row r="1">
      <c r="A1" t="inlineStr"><is><t>Tên thực phẩm</t></is></c>
      <c r="B1" t="inlineStr"><is><t>Khối lượng (g)</t></is></c>
      <c r="C1" t="inlineStr"><is><t>Calo (kcal)</t></is></c>
      <c r="D1" t="inlineStr"><is><t>Chất đạm (g)</t></is></c>
      <c r="E1" t="inlineStr"><is><t>Tinh bột (g)</t></is></c>
      <c r="F1" t="inlineStr"><is><t>Chất béo (g)</t></is></c>
      <c r="G1" t="inlineStr"><is><t>Chất xơ (g)</t></is></c>
    </row>
""")

        // Data Rows
        items.forEachIndexed { index, food ->
            val rowNum = index + 2
            val nameEscaped = escapeXml(food.name)
            sb.append("""    <row r="$rowNum">
      <c r="A$rowNum" t="inlineStr"><is><t>$nameEscaped</t></is></c>
      <c r="B$rowNum"><v>${food.gramsPerServing}</v></c>
      <c r="C$rowNum"><v>${food.caloriesPerServing}</v></c>
      <c r="D$rowNum"><v>${food.proteinPerServing}</v></c>
      <c r="E$rowNum"><v>${food.carbsPerServing}</v></c>
      <c r="F$rowNum"><v>${food.fatPerServing}</v></c>
      <c r="G$rowNum"><v>${food.fiberPerServing}</v></c>
    </row>
""")
        }

        sb.append("""  </sheetData>
</worksheet>""")
        return sb.toString()
    }

    private fun escapeXml(str: String): String {
        return str.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }
}
