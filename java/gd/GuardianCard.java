package gd;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Calendar;

import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.hssf.record.*;
import org.apache.poi.hssf.model.*;
import org.apache.poi.poifs.filesystem.POIFSFileSystem;
import org.apache.poi.hssf.util.Region;

public class GuardianCard extends Base {
  int payment_per_monthId;
  HSSFWorkbook workbook;
  ExcelUtil eu;
  
  public GuardianCard(String templateName, int payment_per_monthId)throws IOException {
    super();
    this.payment_per_monthId = payment_per_monthId;

    // Excelファイルの読み込み    
    FileInputStream fis = new FileInputStream(templateName);    
    o.println("Excel Template Open !! : " + templateName);
    POIFSFileSystem fs = new POIFSFileSystem(fis);    
    workbook = new HSSFWorkbook(fs);
    eu = new ExcelUtil();
  }

  //@Override
  public String getQueryString() {
    String sql = ""
    + "SELECT * FROM payment_per_months a                 \n"
    + " join employees b on a.user_id = b.user_id \n"
    + " join expense_details c on a.id = c.payment_per_month_id \n"
  	+ " join base_applications d on d.id = a.base_application_id \n"
    + "where                                   \n"
    + " a.id = " + payment_per_monthId + "                \n"
  	+ " and c.credit_card_flg = 1 \n"
  	+ " and c.temporary_flg = 0 \n"
    + " and a.deleted = 0 \n"
    + " and b.deleted = 0 \n"
    + " and c.deleted = 0 \n"
  	+ " and d.deleted = 0 \n"
  	+ " and c.payment_per_case_id is null \n"
    + " order by c.book_no DESC, c.buy_date, c.account_item                \n";
    return sql;
  }

  //@Override
  public void procResultSet(ResultSet res) throws SQLException {
    int count = 0;
  	int index = 0;
  	int countTotal = 0;
    int sheetCount = 0;
    int startFooterRow = 0;
  	int startFooterRowTotal = 0;
    boolean prefix_book_no = false;
  	String book_no = "";
  	String sheetNameTotal = "";
    HSSFSheet curSheet = workbook.getSheetAt(0);
  	HSSFSheet curSheetTotal = workbook.getSheetAt(0);
  	long all_total = 0;
  	long temporary_total = 0;
  	
    while(res.next()) {
      if (index == 0) {
      	sheetCount += 1;
        curSheetTotal = workbook.cloneSheet(0);
        workbook.setSheetName(sheetCount, "temp");
        procSummaryPaymentPerCardHeader(res, curSheetTotal);
      	if (res.getDate("cutoff_end_date") != null) sheetNameTotal = (new SimpleDateFormat("yyyyMM")).format(res.getDate("cutoff_end_date")) + "月締会社カード";
      }
      
      //仮払金合計
      //if (res.getLong("temporary_flg") == 1) { temporary_total += res.getLong("amount"); }
      //経費合計
      //else all_total += res.getLong("amount");
      all_total += res.getLong("amount");
    
      procPaymentPerCardDetail(res, curSheetTotal, ExcelUtil.HEADER_ROW_COUNT + index);
      index += 1;
      
      //if (res.getLong("temporary_flg") == 0) {	
        if (res.getString("book_no").substring(0,3).equals(ExcelUtil.PREFIX_BOOK_NO)) {
          if (prefix_book_no == false) {  
            count = 0;
            sheetCount += 1;
            curSheet = workbook.cloneSheet(0);
            workbook.setSheetName(sheetCount, ExcelUtil.PREFIX_BOOK_NO_CONTENT);
            procPaymentPerCardHeader(res, curSheet);
          }
        	procPaymentPerCardDetail(res, curSheet, ExcelUtil.HEADER_ROW_COUNT + count);
        	count += 1;
        	prefix_book_no = true;
        }
        else {
        	if (prefix_book_no == true) {
        	  if (count > ExcelUtil.DETAIL_ROW_COUNT) { startFooterRow = ExcelUtil.HEADER_ROW_COUNT + count + 1; }
            else startFooterRow = ExcelUtil.HEADER_ROW_COUNT + ExcelUtil.DETAIL_ROW_COUNT + 1;
            eu.procFormatFooter(workbook, curSheet, startFooterRow);
        	  prefix_book_no = false;
        	}
          if (book_no.equals(res.getString("book_no"))) {
            procPaymentPerCardDetail(res, curSheet, ExcelUtil.HEADER_ROW_COUNT + count);
                count += 1;
          }
          else {
            if (book_no != "") {
              if (count > ExcelUtil.DETAIL_ROW_COUNT) { startFooterRow = ExcelUtil.HEADER_ROW_COUNT + count + 1; }
              else startFooterRow = ExcelUtil.HEADER_ROW_COUNT + ExcelUtil.DETAIL_ROW_COUNT + 1;
              eu.procFormatFooter(workbook, curSheet, startFooterRow);
            }
            count = 0;
            sheetCount += 1;
            curSheet = workbook.cloneSheet(0);
            workbook.setSheetName(sheetCount, res.getString("book_no"));
            procPaymentPerCardHeader(res, curSheet);
            procPaymentPerCardDetail(res, curSheet, ExcelUtil.HEADER_ROW_COUNT + count);
            count += 1;
          }
        }
        book_no = res.getString("book_no");
      //}
    }
    
  	if (index > 0) {
      if (index > ExcelUtil.DETAIL_ROW_COUNT) { startFooterRow = ExcelUtil.HEADER_ROW_COUNT + index + 1; }
      else startFooterRow = ExcelUtil.HEADER_ROW_COUNT + ExcelUtil.DETAIL_ROW_COUNT + 1;
      //eu.procSummaryFormatFooter(workbook, curSheetTotal, startFooterRow, all_total, temporary_total);
    	
      if (count > ExcelUtil.DETAIL_ROW_COUNT) { startFooterRow = ExcelUtil.HEADER_ROW_COUNT + count + 1; }
  	  else {
  	  	startFooterRow = ExcelUtil.HEADER_ROW_COUNT + ExcelUtil.DETAIL_ROW_COUNT + 1;
  	  }
      eu.procFormatFooter(workbook, curSheet, startFooterRow);
      
      curSheetTotal = workbook.cloneSheet(1);
      workbook.setSheetName(sheetCount + 1, sheetNameTotal);
      workbook.removeSheetAt(0);
      workbook.removeSheetAt(0);
  	}
  }
  
  public void procPaymentPerCardHeader(ResultSet res, HSSFSheet sheet) throws SQLException {
    if (res.getDate("cutoff_end_date") != null) eu.getCell(sheet,0,0).setCellValue((new SimpleDateFormat("yyyy年MM月")).format(res.getDate("cutoff_end_date")) + "度 会社カード");
  	eu.getCell(sheet,3,0).setCellValue("氏名            " + res.getString("employee_name"));
  	if (res.getString("book_no").substring(0,3).equals(ExcelUtil.PREFIX_BOOK_NO)) {
      eu.getCell(sheet,4,0).setCellValue("受注No");
  	}
  	else {
  	  eu.getCell(sheet,4,0).setCellValue("受注No        " + res.getString("book_no"));
  	}
  }
  
  public void procSummaryPaymentPerCardHeader(ResultSet res, HSSFSheet sheet) throws SQLException {
  	if (res.getDate("cutoff_end_date") != null) eu.getCell(sheet,0,0).setCellValue((new SimpleDateFormat("yyyy年MM月")).format(res.getDate("cutoff_end_date")) + "度 会社カード");
  	eu.getCell(sheet,0,5).setCellValue("所属長");
    if (res.getDate("application_date") != null) eu.getCell(sheet,3,0).setCellValue("提出日         " + (new SimpleDateFormat("yyyy年MM月dd日")).format(res.getDate("application_date")));
    eu.getCell(sheet,4,0).setCellValue("氏名            " + res.getString("employee_name"));
  }

  public void procPaymentPerCardDetail(ResultSet res, HSSFSheet sheet, int row) throws SQLException {
    if (row >= ExcelUtil.HEADER_ROW_COUNT + ExcelUtil.DETAIL_ROW_COUNT) {
      eu.procFormatDetail(workbook, sheet, row);
    }
    if(res.getDate("buy_date") != null) eu.getCell(sheet,row,0).setCellValue((new SimpleDateFormat("yyyy/MM/dd")).format(res.getDate("buy_date")));
    eu.getCell(sheet,row,1).setCellValue(res.getString("book_no"));
    eu.getCell(sheet,row,2).setCellValue(res.getString("account_item"));
    eu.getCell(sheet,row,3).setCellValue(res.getString("content"));
    eu.getCell(sheet,row,5).setCellValue(res.getLong("amount"));
  }
  
  public void writeExcel(String fileName) throws IOException{
    eu.writeExcel(workbook, fileName);
  }
  
  /**
   *      0     1      2      3    4          5
   * args [url] [user] [pass] [id] [template] [output]  
   * @param args
   */
  public static void main(String[] args) {
    
    try {
      if(args.length < 6) throw new Exception("usage args.. [url] [user] [pass] [id] [template] [output]");
      String url = args[0];
      String user = args[1];
      String pass = args[2];
      int id = Integer.valueOf(args[3]).intValue();
      String template = args[4];
      String output = args[5];
      
      Base obj = new GuardianCard(template, id);
      obj.doProc(url, user, pass);
      obj.writeExcel(output);
    }catch(Exception e){
      e.printStackTrace();
    }
  }
}
