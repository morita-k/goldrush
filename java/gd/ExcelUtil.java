package gd;

import org.apache.poi.POIXMLProperties;
import org.apache.poi.hpsf.*;
import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.hssf.util.Region;
import org.apache.poi.openxml4j.util.Nullable;
import org.apache.poi.poifs.filesystem.DirectoryEntry;
import org.apache.poi.poifs.filesystem.DocumentEntry;
import org.apache.poi.poifs.filesystem.DocumentInputStream;
import org.apache.poi.poifs.filesystem.POIFSFileSystem;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.xwpf.usermodel.XWPFDocument;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

public class ExcelUtil {
  PrintStream o;
  public static final int HEADER_ROW_COUNT = 7;
  public static final int DETAIL_ROW_COUNT = 35;
  public static final String PREFIX_BOOK_NO = "999";
  public static final String PREFIX_BOOK_NO_CONTENT = "一般管理費";
	
  public ExcelUtil(){
      o = System.out;
  }

  public void writeExcel(HSSFWorkbook workbook, String fileName) throws IOException{
    FileOutputStream out = null;
    try{
      out = new FileOutputStream(fileName);
      workbook.write(out);
    }finally{
      o.println("Excel Close!!");
      if (out != null) out.close();
      else o.println("Error don't open file.. " + fileName);
    }

  }
  
  public String getFormatDate(Date date){
    return (new SimpleDateFormat("yyyy/MM/dd HH:mm")).format(date);
  }

  public HSSFCell getCell(HSSFSheet sheet, int row, int col){
    // Row,Colがなければcreateして返す
    if (sheet.getRow(row) == null) sheet.createRow(row);
    if (sheet.getRow(row).getCell(col) == null) sheet.getRow(row).createCell((short)col);
    // 文字化け対応
    sheet.getRow(row).getCell(col);
    return sheet.getRow(row).getCell(col);
  }
  
  public void procFormatDetail(HSSFWorkbook workbook, HSSFSheet sheet, int num_row) throws SQLException {
    HSSFCellStyle style = workbook.createCellStyle();
    style.setBorderBottom(HSSFCellStyle.BORDER_THIN);
    style.setBorderRight(HSSFCellStyle.BORDER_THIN);
  	
  	HSSFCellStyle style2 = workbook.createCellStyle();
    style2.setBorderBottom(HSSFCellStyle.BORDER_THIN);
    
  	HSSFRow row_default = sheet.getRow(HEADER_ROW_COUNT);
  	HSSFRow row = sheet.createRow(num_row);
    row.setHeight(row_default.getHeight());

    HSSFCell cell0 = row.createCell((short)0);
    cell0.setCellStyle(style);
    HSSFCell cell1 = row.createCell((short)1);
    cell1.setCellStyle(style);
    HSSFCell cell2 = row.createCell((short)2);
    cell2.setCellStyle(style);
    HSSFCell cell3 = row.createCell((short)3);
    cell3.setCellStyle(style2);
    HSSFCell cell4 = row.createCell((short)4);
    cell4.setCellStyle(style);
  	sheet.addMergedRegion(new Region(num_row, (short)3, num_row, (short)4));

    HSSFCellStyle style3 = workbook.createCellStyle();
  	style3.setDataFormat(HSSFDataFormat.getBuiltinFormat("#,##0"));
    style3.setBorderBottom(HSSFCellStyle.BORDER_THIN);
    style3.setBorderRight(HSSFCellStyle.BORDER_THIN);
  	HSSFCell cell5 = row.createCell((short)5);
    cell5.setCellStyle(style3);
  	
  	//HSSFCell cell5 = row.createCell((short)5);
    //cell5.setCellStyle(style);
  }

  public void procFormatFooter(HSSFWorkbook workbook, HSSFSheet sheet, int num_row) throws SQLException {
    HSSFCellStyle style = workbook.createCellStyle();
    style.setAlignment(HSSFCellStyle.ALIGN_LEFT);
    style.setBorderBottom(HSSFCellStyle.BORDER_DOUBLE);
    
    HSSFCellStyle style2 = workbook.createCellStyle();
    style2.setDataFormat(HSSFDataFormat.getBuiltinFormat("#,##0"));
    style2.setBorderBottom(HSSFCellStyle.BORDER_DOUBLE);

    HSSFFont font = workbook.createFont();
    font.setFontName("ＭＳ Ｐゴシック");
    font.setFontHeightInPoints((short)16);
    
    style.setFont(font);
    style2.setFont(font);
    
  	HSSFRow row_default = sheet.getRow(HEADER_ROW_COUNT);
  	HSSFRow row = sheet.createRow(num_row);
    row.setHeight(row_default.getHeight());
    //HSSFRow row = sheet.getRow(num_row);
  	
    HSSFCell cell3 = row.createCell((short)4);
    cell3.setCellStyle(style);
    HSSFCell cell4 = row.createCell((short)5);
    cell4.setCellStyle(style2);
    
    getCell(sheet,num_row,4).setCellValue("合計");
    cell4.setCellFormula("SUM(F8:F" + num_row + ")");
  }
	
  public void procSummaryFormatFooter(HSSFWorkbook workbook, HSSFSheet sheet, int num_row, 
                                      long all_total, long temporary_total) throws SQLException {
                                      	
    HSSFCellStyle style_dot = workbook.createCellStyle();
    style_dot.setBorderBottom(HSSFCellStyle.BORDER_DASHED);
    
    HSSFCellStyle style_thin = workbook.createCellStyle();
    style_thin.setBorderBottom(HSSFCellStyle.BORDER_THIN);
                                      
    HSSFCellStyle style_company_name = workbook.createCellStyle();
    style_company_name.setAlignment(HSSFCellStyle.ALIGN_LEFT);
    
    HSSFCellStyle style_date = workbook.createCellStyle();
    style_date.setBorderBottom(HSSFCellStyle.BORDER_THIN);
    style_date.setAlignment(HSSFCellStyle.ALIGN_RIGHT);
                                      	
    HSSFCellStyle style_amount = workbook.createCellStyle();
    style_amount.setDataFormat(HSSFDataFormat.getBuiltinFormat("#,##0"));
    style_amount.setBorderBottom(HSSFCellStyle.BORDER_THIN);

    HSSFFont font_company_name = workbook.createFont();
    font_company_name.setFontName("ＭＳ Ｐゴシック");
    font_company_name.setFontHeightInPoints((short)11);
    font_company_name.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
    style_company_name.setFont(font_company_name);
    
    //rowを作成  
    HSSFRow row_default = sheet.getRow(HEADER_ROW_COUNT);
  	                                  	
    HSSFRow row_dot = sheet.createRow(num_row-1);
    row_dot.setHeight(row_default.getHeight());
    num_row += 2;
    HSSFRow row_company_name = sheet.createRow(num_row);
    row_company_name.setHeight(row_default.getHeight());
    HSSFRow row_total1 = sheet.createRow(num_row + 2);
    row_total1.setHeight(row_default.getHeight());
    HSSFRow row_total2 = sheet.createRow(num_row + 3);
    row_total2.setHeight(row_default.getHeight());
    HSSFRow row_total3 = sheet.createRow(num_row + 4);
    row_total3.setHeight(row_default.getHeight());
    
    //cellを作成
    //dot行
    HSSFCell cell_dot0 = row_dot.createCell((short)0);
    cell_dot0.setCellStyle(style_dot);
    HSSFCell cell_dot1 = row_dot.createCell((short)1);
    cell_dot1.setCellStyle(style_dot);
    HSSFCell cell_dot2 = row_dot.createCell((short)2);
    cell_dot2.setCellStyle(style_dot);
    HSSFCell cell_dot3 = row_dot.createCell((short)3);
    cell_dot3.setCellStyle(style_dot);
    HSSFCell cell_dot4 = row_dot.createCell((short)4);
    cell_dot4.setCellStyle(style_dot);
    HSSFCell cell_dot5 = row_dot.createCell((short)5);
    cell_dot5.setCellStyle(style_dot);
    	
    //会社名と日付                             	
    HSSFCell cell_company_name = row_company_name.createCell((short)0);
    cell_company_name.setCellStyle(style_company_name);
    HSSFCell cell_date1 = row_company_name.createCell((short)4);
    cell_date1.setCellStyle(style_thin);
    HSSFCell cell_date2 = row_company_name.createCell((short)5);
    cell_date2.setCellStyle(style_date);
    
    //合計
    HSSFCell cell_total1_0 = row_total1.createCell((short)0);
    cell_total1_0.setCellStyle(style_thin);
    HSSFCell cell_total1_1 = row_total1.createCell((short)1);
    cell_total1_1.setCellStyle(style_thin);
    HSSFCell cell_total1_2 = row_total1.createCell((short)2);
    cell_total1_2.setCellStyle(style_amount);

    HSSFCell cell_total2_0 = row_total2.createCell((short)0);
    cell_total2_0.setCellStyle(style_thin);
    HSSFCell cell_total2_1 = row_total2.createCell((short)1);
    cell_total2_1.setCellStyle(style_thin);
    HSSFCell cell_total2_2 = row_total2.createCell((short)2);
    cell_total2_2.setCellStyle(style_amount);

    HSSFCell cell_total3_0 = row_total3.createCell((short)0);
    cell_total3_0.setCellStyle(style_thin);
    HSSFCell cell_total3_1 = row_total3.createCell((short)1);
    cell_total3_1.setCellStyle(style_thin);
    HSSFCell cell_total3_2 = row_total3.createCell((short)2);
    cell_total3_2.setCellStyle(style_amount);
    HSSFCell cell_total3_4 = row_total3.createCell((short)4);
    cell_total3_4.setCellStyle(style_thin);
    HSSFCell cell_total3_5 = row_total3.createCell((short)5);
    cell_total3_5.setCellStyle(style_thin);
    
    //内容
    getCell(sheet,num_row,0).setCellValue("株式会社インフロント");
    getCell(sheet,num_row,5).setCellValue("平成　　　年　　　　　月　　　　　日");
                                      	
    getCell(sheet,num_row + 2,0).setCellValue("経費合計");
    getCell(sheet,num_row + 3,0).setCellValue("仮払金合計");
    getCell(sheet,num_row + 4,0).setCellValue("差引金額");
    getCell(sheet,num_row + 3,4).setCellValue("サイン又は印");
                                      	
    getCell(sheet,num_row + 2,2).setCellValue(all_total);
    getCell(sheet,num_row + 3,2).setCellValue(temporary_total);
    getCell(sheet,num_row + 4,2).setCellValue(all_total - temporary_total);
  }

  public void setProperty(String fileName) throws IOException {
    FileOutputStream out = null;
    FileInputStream fis = new FileInputStream(fileName);
    POIFSFileSystem fs = new POIFSFileSystem(fis);
    DirectoryEntry dir = fs.getRoot();
    SummaryInformation si;
    try{
        out = new FileOutputStream(fileName);
        DocumentEntry dsiEntry = (DocumentEntry)dir.getEntry(SummaryInformation.DEFAULT_STREAM_NAME);
        DocumentInputStream dis = new DocumentInputStream(dsiEntry);
        PropertySet ps = new PropertySet(dis);
        dis.close();
        si = new SummaryInformation(ps);
        si.setAuthor("アプリカティブ株式会社");
        si.setLastAuthor("アプリカティブ株式会社");
        si.setCreateDateTime(new Date());
        si.setLastSaveDateTime(new Date());
        si.write(dir, SummaryInformation.DEFAULT_STREAM_NAME);
        fs.writeFilesystem(out);
    } catch (NoPropertySetStreamException e) {
        e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
    } catch (MarkUnsupportedException e) {
        e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
    } catch (UnexpectedPropertySetTypeException e) {
        e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
    } catch (WritingNotSupportedException e) {
        e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
    } finally{
      o.println("Excel/Doc Close!!");
      if (out != null) out.close();
      else o.println("Error don't open file.. " + fileName);
    }
  }

    public void setDocxProperty(String fileName) throws IOException {
        o.println(fileName);
        FileInputStream fis = new FileInputStream(fileName);
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("JST"));
        o.println(cal.getTime());
        try{
            XWPFDocument docx = new XWPFDocument(fis);
            fis.close();
            FileOutputStream fos = new FileOutputStream(fileName);
            POIXMLProperties.CoreProperties coreProperties = docx.getProperties().getCoreProperties();
            coreProperties.setCreator("アプリカティブ株式会社");
            coreProperties.setCreated(new Nullable<Date>(cal.getTime()));
            coreProperties.setModified(new Nullable<Date>(cal.getTime()));
            docx.write(fos);
            fos.close();
        }finally{
            o.println("Docx Close!!");
        }
    }

    public void setXlsxProperty(String fileName) throws IOException {
        o.println(fileName);
        FileInputStream fis = new FileInputStream(fileName);
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("JST"));
        try{
            XSSFWorkbook xlsx = new XSSFWorkbook(fis);
            fis.close();
            FileOutputStream fos = new FileOutputStream(fileName);
            POIXMLProperties.CoreProperties coreProperties = xlsx.getProperties().getCoreProperties();
            coreProperties.setCreator("アプリカティブ株式会社");
            coreProperties.setCreated(new Nullable<Date>(cal.getTime()));
            coreProperties.setModified(new Nullable<Date>(cal.getTime()));
            xlsx.write(fos);
            fos.close();
        }finally{
            o.println("Xlsx Close!!");
        }
    }
}
