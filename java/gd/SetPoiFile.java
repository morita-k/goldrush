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
                writeExcel(res.getString("file_path"), res.getString("extention"));
            } catch (IOException e) {
                e.getStackTrace();
            }
        }
    }

    private void writeExcel(String fileName, String extention) throws  IOException{
        String allFileName = root + "/" + fileName;
        if(extention.contains(".docx")){
            eu.setDocxProperty(allFileName);
        }else if(extention.contains(".xlsx")){
            eu.setXlsxProperty(allFileName);
        }else{
            eu.setProperty(allFileName);
        }
    }

    @Override
    public void writeExcel(String fileName) throws IOException {
    }
}
