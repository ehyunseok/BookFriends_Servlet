<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.PrintWriter"%>
<%@ page import="user.UserDao"%>
<%@ page import="board.BoardDao"%>
<%@ page import="board.BoardDto"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.net.URLEncoder"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
	<title>이현대학교 대나무숲</title>
	<!-- 부트스트랩 css 추가하기 -->
	<link rel="stylesheet" href="./css/bootstrap.min.css">
	<!-- 커스텀 css 추가하기 -->
	<link rel="stylesheet" href="./css/custom.css">
</head>
<body>

<%
//검색했을 때 어떤 게시글을 검색했는지 판단할 수 있게~
	request.setCharacterEncoding("UTF-8");
	int postID = 0;
	String postCategory = "전체";
	String searchType = "최신순";
	String search = "";
	int pageNumber = 0;
	if(request.getParameter("postCategory") != null){
		postCategory = request.getParameter("postCategory");
	}
	if(request.getParameter("searchType") != null){
		searchType = request.getParameter("searchType");
	}
	if(request.getParameter("search") != null){
		search = request.getParameter("search");
	}
	if(request.getParameter("pageNumber") != null){
		try{
			pageNumber = Integer.parseInt( request.getParameter("pageNumber") );
		} catch(Exception e){
			System.out.println("검색 페이지 오류");
			e.printStackTrace();
		}
	}
	if(request.getParameter("postID") != null){
		try{
			postID = Integer.parseInt( request.getParameter("postID") );
		} catch(Exception e){
			System.out.println("게시글 아이디 불러오기 오류");
			e.printStackTrace();
		}
	}
	
// 로그인 상태 관리
	String userID = null;
	if(session.getAttribute("userID") != null){		// 로그인한 상태라서 세션에 userID가 존재할 경우
		userID = (String)session.getAttribute("userID");	// userID에 해당 세션의 값을 저장함
	}
	if(userID == null){		// 로그인 상태가 아닌 경우에는 로그인 페이지로 이동
		PrintWriter script = response.getWriter();
		script.println("<script>");
		script.println("alert('로그인을 해주세요.');");
		script.println("location.href='userLogin.jsp'");
		script.println("</script>");
		script.close();
		return;
	}
	
	// 이메일이 인증되지 않은 회원은 수강 평가를 할 수 없도록 기존 이메일 인증 페이지로 이동하게 함 
	boolean emailChecked = new UserDao().getUserEmailChecked(userID);
	if(emailChecked == false){
		PrintWriter script = response.getWriter();
		script.println("<script>");
		script.println("location.href='emailSendConfirm.jsp'");
		script.println("</script>");
		script.close();
		return;
	}
%>

<!-- navigation -->
	<nav class="navbar navbar-expand-lg navbar-light bg-light">
		<a class="navbar-brand" href="index.jsp">이현대학교 대나무숲</a>
		<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbar">
			<span class="navbar-toggler-icon"></span>
		</button>
		<div id="navbar" class="collapse navbar-collapse">
			<ul class="navbar-nav mr-auto">
				<li class="nav-item">
					<a class="nav-link" href="index.jsp">메인</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="./courseReview.jsp">강의평가</a>
				</li>				
				<li class="nav-item active">
					<a class="nav-link" href="./board.jsp"><b>자유게시판</b></a>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" id="dropdown" data-toggle="dropdown">
						회원관리
					</a>
					<div class="dropdown-menu" aria-labelledby="dropdown">
						<a class="dropdown-item" style="color: green;"><b><%= userID %></b> 님 환영합니다.</a>
						<a class="dropdown-item" href="userLogoutAction.jsp">로그아웃</a>
					</div>
				</li>
			</ul>
		</div>
	</nav>
	
<!-- container  -->
	<section class="container">
		<form method="get" action="./board.jsp" class="form-inline mt-3">
			<select name="postCategory" class="form-control mx-1 mt-2">
				<option value="전체">전체</option>
				<option value="질문" <% if(postCategory.equals("질문")) out.println("selected"); %>>질문</option>
				<option value="맛집 추천" <% if(postCategory.equals("맛집")) out.println("selected"); %>>맛집 추천</option>
				<option value="사담" <% if(postCategory.equals("사담")) out.println("selected"); %>>사담</option>
			</select>
			<select name="searchType" class="form-control mx-1 mt-2">
				<option value="최신순">최신순</option>
				<option value="조회수순" <% if(searchType.equals("조회수")) out.println("selected"); %>>조회수순</option>
				<option value="추천순" <% if(searchType.equals("추천순")) out.println("selected"); %>>추천순</option>
			</select>
			<input type="text" name="search" class="form-control mx-1 mt-2" placeholder="내용을 입력해주세요.">
			<button type="submit" class="btn btn-dark mx-1 mt-2">검색</button>
			<div class="ml-auto">
				<a class="btn btn-primary mx-1 mt-2" data-toggle="modal" href="#registerModal">작성하기</a>
				<a class="btn btn-outline-danger mx-1 mt-2" data-toggle="modal" href="#reportModal">신고</a>
			</div>
		</form>
		<div class="card bg-light mt-3">
			<table class="table table-hover">
				<thead>
					<tr>
						<th scope="col" style="">#</th>
						<th scope="col" style="">카테고리</th>
						<th scope="col" style="">제목</th>
						<th scope="col" style="">작성자</th>
						<th scope="col" style="">작성일</th>
						<th scope="col" style="">조회수</th>
					</tr>
				</thead>
				<tbody>
<%
//사용자가 검색한 내용이 리스트에 담긴 상태로 출력되게 하기
	ArrayList<BoardDto> boardList = new ArrayList<BoardDto>();

	boardList = new BoardDao().getList(postCategory, searchType, search, pageNumber);

	int totalPosts = boardList.size();	// boardList의 크기에 따른 총 게시글 수 확인
	int postsPerPage = 5;	// 페이지당 5개의 글을 불러옴
	int totalPages = (int)Math.ceil( (double)boardList.size() / 5 );	// 전체 페이지 수 계산
	int currentPage = pageNumber +1; // 현재 페이지 번호 가져오기(0부터 시작해서 1을 더함)
	int startPage = Math.max(1, pageNumber - 2); // 시작 페이지 번호 계산
    int endPage = Math.min(startPage + 4, totalPages); // 끝 페이지 번호 계산
	int startIndex = pageNumber * postsPerPage;	//시작 인덱스 계산
	int endIndex = Math.min(startIndex + postsPerPage, totalPosts);	// 끝 인덱스 계산
	
	for(int i = startIndex; i<endIndex; i++){
		BoardDto board = boardList.get(i);
%>

			  		<!-- 해당 게시글 번호 페이지로 이동 -->
			  		<tr onclick="window.location='./postDetail.jsp?postID=<%= board.getPostID() %>'">	
					    <th scope="row"><%= board.getPostID() %></th>
					    <td><%= board.getPostCategory() %></td>
					    <td><%= board.getPostTitle() %> <small>(추천: <%= board.getLikeCount() %>)</small></td>
					    <td><%= board.getUserID() %></td>
					    <td><%= board.getPostDate() %></td>
					    <td><%= board.getViewCount() %></td>
				    </tr>
<%
	}
%>
				</tbody>
				<tfoot></tfoot>				
			</table>
		</div>
	</section>
	
	
	
<!-- pagination -->
		<nav aria-label="Page navigation example" >
		  <ul class="pagination justify-content-center mt-3" style="padding-bottom: 3px;">
		    <li class="page-item">
	            <a class="page-link <%= currentPage <= 1 ? "disabled" : "" %>" href="./board.jsp?postCategory=<%= URLEncoder.encode(postCategory, "UTF-8") %>&searchType=<%= URLEncoder.encode(searchType, "UTF-8") %>&search=<%= URLEncoder.encode(search, "UTF-8") %>&pageNumber=<%= currentPage - 2 %>" aria-label="Previous">
	                <span aria-hidden="true">이전</span>
	            </a>
        	</li>
<%
    for (int i = 1; i <= totalPages; i++) { 
%>
			<li class="page-item <%= currentPage == i ? "active" : "" %>">
            	<a class="page-link" href="./board.jsp?postCategory=<%= URLEncoder.encode(postCategory, "UTF-8") %>&searchType=<%= URLEncoder.encode(searchType, "UTF-8") %>&search=<%= URLEncoder.encode(search, "UTF-8") %>&pageNumber=<%= i - 1 %>"><%= i %></a>
        </li>
<% } 
%>
		    <li class="page-item">
	            <a class="page-link <%= currentPage >= totalPages ? "disabled" : "" %>" href="./board.jsp?postCategory=<%= URLEncoder.encode(postCategory, "UTF-8") %>&searchType=<%= URLEncoder.encode(searchType, "UTF-8") %>&search=<%= URLEncoder.encode(search, "UTF-8") %>&pageNumber=<%= currentPage %>" aria-label="Next">
	                <span aria-hidden="true">다음</span>
	            </a>
        	</li>
		  </ul>
		</nav>

	
<!-- 게시글 등록하기 모달  -->
	<div class="modal fade" id="registerModal" tabindex="-1" role="dialog" aria-labelledby="modal">
		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title" id="modal">게시글 작성</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<span aria-hidden="true">&times;</span>
					</button>
				</div>
				<div class="modal-body">
					<form method="post" action="./postRegisterAction.jsp">
						<div class="form-row">
							<div class="form-group col-sm-4">
								<label>카테고리</label>
								<select name="postCategory" class="form-control">
									<option value="질문">질문</option>
									<option value="맛집 추천">맛집 추천</option>
									<option value="사담">사담</option>
								</select>
							</div>
						</div>
						<div class="form-group">
							<label>제목</label>
							<input type="text" name="postTitle" class="form-control" maxlength="30">
						</div>
						<div class="form-group">
							<label>내용</label>
							<textarea name="postContent" class="form-control" maxlength="2048" style="height: 180px;"></textarea>
						</div>
						<div class="modal-footer">
							<button type="button" class="btn btn-secondary" data-dismiss="modal">취소</button>
							<button type="submit" class="btn btn-primary">등록</button>
						</div>
					</form>
				</div>
			</div>
		</div>
	</div>
	
<!-- 신고하기 모달  -->
	<div class="modal fade" id="reportModal" tabindex="-1" role="dialog" aria-labelledby="modal">
		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title" id="modal">신고하기</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<span aria-hidden="true">&times;</span>
					</button>
				</div>
				<div class="modal-body">
					<form action="./reportAction.jsp" method="post">
						<div class="form-group">
							<label>신고 제목</label>
							<input type="text" name="reportTitle" class="form-control" maxlength="30">
						</div>
						<div class="form-group">
							<label>신고 내용</label>
							<textarea name="reportContent" class="form-control" maxlength="2048" style="height: 180px;"></textarea>
						</div>
						<div class="modal-footer">
							<button type="button" class="btn btn-secondary" data-dismiss="modal">취소</button>
							<button type="submit" class="btn btn-danger">신고하기</button>
						</div>
					</form>
				</div>
			</div>
		</div>
	</div>
	
<!-- footer -->
	<footer class="fixed-bottom bg-dark text-center mt-5" style="color: #FFFFFF;">
		Copyright &copy; 2024 EhyunSeok All Rights Reserved.
	</footer>
	

<!--  -->
	<!-- jquery js 추가하기 -->
	<script src="./js/jquery.min.js"></script>
	<!-- popper js 추가하기 -->
	<script src="./js/popper.min.js"></script>
	<!-- bootstrap js 추가하기 -->
	<script src="./js/bootstrap.min.js"></script>
</body>
</html>