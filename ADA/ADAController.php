<?php
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: *');
    header('Content-Type: application/json');
include "Model/CompanyDB.php";
isset($_POST['Function']) ? $function = $_POST['Function'] : $function = '404';

switch ($function){
	case 'ExecuteReport': CompanyController::ExecuteReport();
	break;
    case 'saveContent': CompanyController::saveContent();
    break;
    case 'GetReporteContent': CompanyController::GetReporteInfo();
    break;
    case 'updateAppInfo': CompanyController::updateAppInfo();
    break;
	case 'ExecuteQuery': CompanyController::ExecuteQuery();
	break;
	case 'updateReporte': CompanyController::updateReporte();
	break;
    case 'updateReporte2': CompanyController::updateReporte2();
    break;
	case 'updateTabla': CompanyController::updateTabla();
	break;
	case 'updateProcedure': CompanyController::updateProcedure();
	break;
	case 'GetAllProcedimientos': CompanyController::GetAllProcedimientos();
	break;
    case 'GetAllParams': CompanyController::GetAllParams();
    break;
	case 'GetAllReportes': CompanyController::GetAllReportes();
	break;
    case 'GetReporteInfo': CompanyController::GetReporteInfo();
    break;
	case 'GetData': CompanyController::GetData();
	break;
	case 'SetData': CompanyController::SetData();
	break;
	case 'GetAllTablas': CompanyController::GetAllTablas();
	break;
	case 'GetTablasToShow': CompanyController::GetTablasToShow();
	break;
	case 'GetReportesToShow': CompanyController::GetReportesToShow();
	break;
	case 'GetProcedimientosToShow': CompanyController::GetProcedimientosToShow();
	break;
	case 'GetCamposTablas': CompanyController::GetCamposTablas();
	break;
	case 'GetCamposReporte': CompanyController::GetCamposReporte();
	break;
	case 'DeleteCampos': CompanyController::DeleteCampos();
	break;
	case 'InsertCampo': CompanyController::InsertCampo();
	break;
	case 'InsertReporte': CompanyController::InsertReporte();
	break;
	case 'GetProcsReporte': CompanyController::GetProcsReporte();
	break;
	case 'DeleteProcsRep': CompanyController::DeleteProcsRep();
	break;
	case 'InsertProcsRep': CompanyController::InsertProcsRep();
	break;
	case 'DeleteReporte': CompanyController::DeleteReporte();
	break;
	case '404': header("HTTP/1.1 404 Not Found");
	break;
	default: header("HTTP/1.1 400 Bad Request");
	break;
}
class CompanyController{
	public function GetProcsReporte()
	{
		echo json_encode(CompanyDB::GetProcsReporte($_POST['id']));
	}
	public function DeleteReporte()
	{
		echo json_encode(CompanyDB::DeleteReporte($_POST['id']));
	}
	public function GetReportesToShow()
	{
		echo json_encode(CompanyDB::GetReportesToShow());
	}
	public function GetProcedimientosToShow()
	{
		echo json_encode(CompanyDB::GetProcedimientosToShow());
	}
	public function DeleteCampos()
	{
		echo json_encode(CompanyDB::DeleteCampos($_POST['id'], $_POST['isReporte']));
	}

	public function DeleteProcsRep()
	{
		echo json_encode(CompanyDB::DeleteProcsRep($_POST['id']));
	}

	public function InsertReporte()
	{
		echo json_encode(CompanyDB::InsertReporte($_POST['nombre'], $_POST['titulo']));
	}

	public function InsertCampo()
	{
		echo json_encode(CompanyDB::InsertCampo($_POST['id'], $_POST['titulo'], $_POST['tipo'], $_POST['orden'],$_POST['isReporte']));
	}

	public function InsertProcsRep()
	{
		echo json_encode(CompanyDB::InsertProcsRep($_POST['idRep'], $_POST['idProc'], $_POST['orden']));
	}

	public function GetTablasToShow()
	{
		echo json_encode(CompanyDB::GetTablasToShow());
	}

	public function GetCamposTablas()
	{
		echo json_encode(CompanyDB::GetCamposTablas($_POST['id']));
	}

	public function GetCamposReporte()
	{
		echo json_encode(CompanyDB::GetCamposReporte($_POST['id']));
	}
    
    public function GetReporteInfo()
    {
        echo json_encode(CompanyDB::GetReporteInfo($_POST['id']));
    }


	public function ExecuteQuery()
	{
		$sp = $_POST['SProcedure'];
		$params = array();
		
		for ($i = 0; $i < $_POST['size']; $i = $i + 1){
			$params[] = json_decode($_POST['params'])[$i];
		}
		echo json_encode(CompanyDB::ExecuteQuery($sp, $params, $_POST['size']));
	}

	public function ExecuteReport()
	{
		$sp = $_POST['SProcedure'];
		echo json_encode(CompanyDB::ExecuteReport($sp));
	}

	public function updateProcedure()
	{

		echo json_encode(CompanyDB::updateProcedure($_POST['id'], $_POST['titulo'], $_POST['mostrar']));
	}
	public function updateTabla ()
	{
		echo json_encode(CompanyDB::updateTabla($_POST['id'], $_POST['titulo'], $_POST['proc'] , $_POST['mostrar']));
	}

    
    public function saveContent ()
    {
        echo json_encode(CompanyDB::saveContent($_POST['id'], $_POST['content']));
    }
	public function updateReporte ()
	{
		echo json_encode(CompanyDB::updateReporte($_POST['id'], $_POST['titulo'] , $_POST['mostrar']));
	}
    
    public function updateReporte2 ()
    {
        echo json_encode(CompanyDB::updateReporte2($_POST['id'], $_POST['nombre'] , $_POST['buttonUI'],$_POST['icon']));
    }
    
    public function updateAppInfo ()
    {
        echo json_encode(CompanyDB::updateAppInfo($_POST['id'], $_POST['app_name'],$_POST['color1'],
                                                  $_POST['color2'], $_POST['home_name'],
                                                  $_POST['home_icon'],$_POST['button1_name'],
                                                  $_POST['button1_icon'],   $_POST['button1_show'],$_POST['button2_name'],
                                               
                                                  $_POST['button2_icon'],$_POST['button2_show'],
                                                  
                                                  $_POST['button3_name'],$_POST['button3_icon'],
                                                  $_POST['button3_show'],$_POST['button4_name'],
                                                  $_POST['button4_icon'],$_POST['button4_show'],
                                                  
                                                  $_POST['button5_name'],$_POST['button5_icon'],
                                                  $_POST['button5_show'],$_POST['button6_name'],
                                                  $_POST['button6_icon'],$_POST['button6_show']
                                                  ));
    }
    
	public function GetAllProcedimientos ()
	{
		echo json_encode(CompanyDB::GetProcedimientos());
	}

	public function GetAllTablas ()
	{
		echo json_encode(CompanyDB::GetTablas());
	}
    
    public function GetAllParams ()
    {
        echo json_encode(CompanyDB::GetParams());
    }

	public function GetAllReportes ()
	{
		echo json_encode(CompanyDB::GetAllReportes());
	}
    

	public function GetData ()
	{
		$arr = array(); 
		if (isset($_COOKIE['titulo'])){
			$arr['titulo'] = $_COOKIE['titulo'];
		}

		if (isset($_COOKIE['servidor'])){
			$arr['servidor'] = $_COOKIE['servidor'];
		}

		if (isset($_COOKIE['pass'])){
			$arr['pass'] = $_COOKIE['pass'];
		}

		if (isset($_COOKIE['bd'])){
			$arr['bd'] = $_COOKIE['bd'];
		}

		if (isset($_COOKIE['usr'])){
			$arr['usr'] = $_COOKIE['usr'];
		}
     
		echo json_encode(CompanyDB::GetAllInfoInfo());
	}

	public function SetData ()
	{
		$arr = array(); 
		$arr[] = 1;
        
		setcookie("titulo", $_POST['Titulo'], time() + (86400 * 360), "/");
		setcookie("servidor", $_POST['Servidor'], time() + (86400 * 360), "/");
		setcookie("pass", $_POST['Contrasena'], time() + (86400 * 360), "/");
		setcookie("bd", $_POST['BD'], time() + (86400 * 360), "/");
		setcookie("usr", $_POST['Usr'], time() + (86400 * 360), "/");
		echo json_encode(CompanyDB::GetAllInfo());
	}
}
?>
