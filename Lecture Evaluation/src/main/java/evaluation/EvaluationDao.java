package evaluation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;

import util.DatabaseUtil;

public class EvaluationDao {

	//사용자가 강의 평가를 작성할 수 있는 함수
		public int write(EvaluationDto evalDto) {
			
			String SQL = "INSERT INTO EVALUATION VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0);";
			
			Connection conn = null;
			PreparedStatement pstmt = null;
			ResultSet rs = null;
			
			try {
				conn = DatabaseUtil.getConnection();
				pstmt = conn.prepareStatement(SQL);
				pstmt.setString(1, evalDto.userID);
				pstmt.setString(2, evalDto.lectureName);
				pstmt.setString(3, evalDto.professorName);
				pstmt.setInt(4, evalDto.lectureYear);
				pstmt.setString(5, evalDto.semesterDivide);
				pstmt.setString(6, evalDto.lectureDivide);
				pstmt.setString(7, evalDto.evaluationTitle);
				pstmt.setString(8, evalDto.evaluationContent);
				pstmt.setString(9, evalDto.totalScore);
				pstmt.setString(10, evalDto.usabilityScore);
				pstmt.setString(11, evalDto.skillScore);
				return pstmt.executeUpdate();	// insert구문을 실행한 결과를 반환함
				
			} catch(Exception e) {
				e.printStackTrace();
			} finally {
				try { if(conn != null) conn.close();} catch(Exception e ) {e.printStackTrace();}
				try { if(pstmt != null) pstmt.close();} catch(Exception e ) {e.printStackTrace();}
				try { if(rs != null) rs.close();} catch(Exception e ) {e.printStackTrace();}
			}
			return -1; // db 오류

		}
		
		public ArrayList<EvaluationDto> getList(String lectureDivide, String searchType, String search, int pageNumber) {
		    if (lectureDivide.equals("전체")) {
		        lectureDivide = "";
		    }
		    
		    ArrayList<EvaluationDto> evalList = null;
		    String SQL = "";
		    
		    Connection conn = null;
		    PreparedStatement pstmt = null;
		    ResultSet rs = null;
		    
		    try {
		        conn = DatabaseUtil.getConnection();
		        
		        if (searchType.equals("최신순")) {
		            SQL = "SELECT * FROM evaluation "
		                + "WHERE lectureDivide LIKE ? "
		                + "AND CONCAT(lectureName, professorName, evaluationTitle, evaluationContent) LIKE ? "
		                + "ORDER BY evaluationID DESC LIMIT ?, ?";
		        } else if (searchType.equals("추천순")) {
		            SQL = "SELECT * FROM evaluation "
		                + "WHERE lectureDivide LIKE ? "
		                + "AND CONCAT(lectureName, professorName, evaluationTitle, evaluationContent) LIKE ? "
		                + "ORDER BY likeCount DESC LIMIT ?, ?";
		        }
		        
		        pstmt = conn.prepareStatement(SQL);
		        pstmt.setString(1, "%" + lectureDivide + "%");
		        pstmt.setString(2, "%" + search + "%");
		        pstmt.setInt(3, pageNumber * 5); // offset 계산
		        pstmt.setInt(4, pageNumber * 5 + 6); // row count
		        
		        rs = pstmt.executeQuery();
		        
		        evalList = new ArrayList<EvaluationDto>(); // 조회 결과를 저장하는 리스트를 초기화함
		        while (rs.next()) { // 모든 게시글이 존재할 때마다 리스트에 담길 수 있게 함
		            EvaluationDto evalDto = new EvaluationDto(
		                    rs.getInt(1),
		                    rs.getString(2),
		                    rs.getString(3),
		                    rs.getString(4),
		                    rs.getInt(5),
		                    rs.getString(6),
		                    rs.getString(7),
		                    rs.getString(8),
		                    rs.getString(9),
		                    rs.getString(10),
		                    rs.getString(11),
		                    rs.getString(12),
		                    rs.getInt(13)
		            );
		            evalList.add(evalDto);
		        }
		    } catch (Exception e) {
		        e.printStackTrace();
		    } finally {
		        try { if (conn != null) conn.close(); } catch (Exception e ) { e.printStackTrace(); }
		        try { if (pstmt != null) pstmt.close(); } catch (Exception e ) { e.printStackTrace(); }
		        try { if (rs != null) rs.close(); } catch (Exception e ) { e.printStackTrace(); }
		    }
		    
		    return evalList;
		}

	
}