prompt --application/pages/page_groups
begin
--   Manifest
--     PAGE GROUPS: 100
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.0'
,p_default_workspace_id=>7600406668646520
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'DEV_USER'
);
wwv_flow_imp_page.create_page_group(
 p_id=>wwv_flow_imp.id(8811377040125004)
,p_group_name=>'Administration'
);
wwv_flow_imp.component_end;
end;
/
