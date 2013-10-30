package gd;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Created with IntelliJ IDEA.
 * User: ryo
 * Date: 2013/10/07
 * Time: 14:46
 * To change this template use File | Settings | File Templates.
 */
public class SetPoiFile extends Base {
    String ids;
    String root;
    ExcelUtil eu;

    public SetPoiFile(String ids, String root)throws IOException {
        super();
        this.ids = ids;
        this.root = root;
        eu = new ExcelUtil();
    }

    @Override
    public String getQueryString() {
        String sql = ""
                + "SELECT * FROM attachment_files \n"
                + " where                                   \n"
                + " id IN (" + ids + ")                \n";
        return sql;
    }

    @Override
    public void procResultSet(ResultSet res) throws SQLException {
        while(res.next()){
            try {
                writeExcel(res.getString("file_path"),res.getString("file_path"), res.getString("extention"), "アプリカティブ株式会社");
            } catch (IOException e) {
                e.getStackTrace();
            }
        }
    }

    public void writeExcel(String inputFileName, String outputFileName, String extention, String author) throws  IOException{
        String allInputFileName = root + "/" + inputFileName;
        String allOutputFileName = root + "/" + outputFileName;
        if(extention.contains(".docx")){
            eu.setDocxProperty(allInputFileName, allOutputFileName, author);
        }else if(extention.contains(".xlsx")){
            eu.setXlsxProperty(allInputFileName, allOutputFileName, author);
        }else{
            eu.setProperty(allInputFileName, allOutputFileName, author);
        }
    }

    @Override
    public void writeExcel(String fileName) throws IOException {
    }
}
