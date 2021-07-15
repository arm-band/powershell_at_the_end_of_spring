# Shift-JIS �ŃR�[�h�L�q

######################
# ���ݒ�            #
######################

# �t�@�C���o�͎��̕����R�[�h�ݒ�
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

######################
# �O���[�o���ϐ�      #
######################
[String]$configPath = Join-Path ( Convert-Path . ) 'config.json'

######################
# �֐�               #
######################

##
# Find-ErrorMessage: �G���[���b�Z�[�W�g�ݗ���
#
# @param {Int} $code: �G���[�R�[�h
# @param {String} $someStr: �ꕔ�G���[���b�Z�[�W�Ŏg�p���镶����
#
# @return {String} $msg: �o�̓��b�Z�[�W
#
function Find-ErrorMessage([Int]$code, [String]$someStr) {
    $msg = ''
    $errMsgObj = [Hashtable]@{
        # 1x: �ݒ�t�@�C���n
        11 = '�ݒ�t�@�C�� (config.json) �����݂��܂���B'
        # 2x: Git �ݒ�t�@�C���n
        21 = '�w�肳�ꂽ �f�B���N�g�� �����݂��܂���B'
        22 = 'Git�ݒ�t�@�C�� (.git/config) �����݂��܂���B'
        ## 31�`39: �����[�g���|�W�g��
        31 = '�����[�g���|�W�g�� �̃I���W�i���� �|�[�g�ԍ� ���w�肳��Ă��܂���B'
        32 = '�����[�g���|�W�g�� �̃I���W�i���� �|�[�g�ԍ� �����t����܂���ł����B'
        33 = '�����[�g���|�W�g�� �̕ϊ���� �|�[�g�ԍ� �̒l���s���ł��B'
        34 = '�����[�g���|�W�g�� �̕ϊ���� �|�[�g�ԍ� ���w�肳��Ă��܂���B'
        35 = '�����[�g���|�W�g�� �̕ϊ���� �|�[�g�ԍ� �̒l���s���ł��B'
        # 9x: ���̑��A�������G���[
        99 = '##########'
    }
    $msg = $errMsgObj[$code]
    if ($someStr.Length -gt 0) {
        $msg = $msg.Replace('##########', $someStr)
    }

    return $msg
}
##
# Show-ErrorMessage: �G���[���b�Z�[�W�o��
#
# @param {Int} $code: �G���[�R�[�h
# @param {Boolean} $exitFlag: exit ���邩�ǂ����̃t���O
# @param {String} $someStr: �ꕔ�G���[���b�Z�[�W�Ŏg�p���镶����
#
function Show-ErrorMessage([Int]$code, [Boolean]$exitFlag, [String]$someStr) {
    $msg = Find-ErrorMessage $code $someStr
    Write-Host('ERROR ' + $code + ': ' + $msg) -BackgroundColor DarkRed
    Write-Host `r`n

    if ($exitFlag) {
        exit
    }
}

##
# Assert-ParamStrGTZero: �p�����[�^�����񒷂��`�F�b�N
#
# @param {String} $paramStr: �t�@�C���p�X
#
# @return {Boolean} : ��������0���傫����� True, �����łȂ���� False
#
function Assert-ParamStrGTZero([String]$paramStr) {
    return ($paramStr.Length -gt 0)
}
##
# Assert-ExistFile: �t�@�C�����݃`�F�b�N
#
# @param {String} $filePath: �t�@�C���p�X
#
# @return {Boolean} : �t�@�C�������݂���� True, ������Ȃ���� False
#
function Assert-ExistFile([String]$filePath) {
    return (Test-Path $filePath)
}
##
# Assert-NumberFormat: ������`���`�F�b�N
#
# @param {String} $asciiStr: ������
#
# @return {Boolean} : �����񂪔��p���������ō\������Ă���� True, ������Ȃ���� False
#
function Assert-NumberFormat([String]$asciiStr) {
    return ($asciiStr -match "^[0-9]+$")
}

##
# Assert-URLFormat: URL�`���`�F�b�N
#
# @param {String} $str: URL���܂ޕ�����
#
# @return {Boolean} : URL���|�[�g�ԍ��t���Ő������Ǝv�����`���Ȃ�� True, ������Ȃ���� False
#
function Assert-URLFormat([String]$str) {
    return ($str -match "url[\s]?=[\s]?https?://([^:/]+):([0-9]+)(/?.*)")
}

##
# Set-GitConfig: Git �̃O���[�o���ݒ�����{�B������ Invoke-ExternalCommand �ɂ�� Git ���O���v���Z�X�Ƃ��ċN��
#
# @param {String} $configPath: config.json.sample �̃t�@�C���p�X
# @param {String} $configPath: config.json �̃t�@�C���p�X
#
function Set-GitConfig([String]$configPath) {
    Write-Host '�ݒ�t�@�C�� (config.json) ��ǂݍ��݂܂� ...'
    Write-Host `r`n
    if (-not (Assert-ExistFile $configPath)) {
        Show-ErrorMessage 11 $True ''
    }

    # �ݒ�t�@�C�� �ǂݍ���
    $configData = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-JSON
    # �����ݒ�
    Write-Host 'Git �����[�g���|�W�g�� �� �|�[�g�ԍ���ύX���܂��B'
    Write-Host `r`n

    # �����[�g���|�W�g��
    if (-not (Assert-ParamStrGTZero $configData.gitConfig.repository.originPort) ) {
        Show-ErrorMessage 31 $True ''
    }
    if (-not (Assert-NumberFormat $configData.gitConfig.repository.originPort) ) {
        Show-ErrorMessage 33 $True ''
    }
    if (-not (Assert-ParamStrGTZero $configData.gitConfig.repository.modifiedPort) ) {
        Show-ErrorMessage 34 $True ''
    }
    if (-not (Assert-NumberFormat $configData.gitConfig.repository.modifiedPort) ) {
        Show-ErrorMessage 35 $True ''
    }

    # ���[�J�����|�W�g��
    [String]$localRepositoryDir = Read-Host '�����[�g���|�W�g���̃|�[�g�ԍ���ύX������ config �����݂��� Git���|�W�g�� �� �f�B���N�g���p�X ����͂��Ă��������B'
    if (-not (Assert-ExistFile $localRepositoryDir)) {
        Show-ErrorMessage 21 $True ''
    }
    [String]$localRepositoryConfig = $localRepositoryDir + '\.git\config'
    if (-not (Assert-ExistFile $localRepositoryConfig)) {
        Show-ErrorMessage 22 $True ''
    }
    $content = Get-Content $localRepositoryConfig -Raw
    if (-not (Assert-URLFormat $content)) {
        Show-ErrorMessage 32 $True ''
    }
    else {
        Write-Host '============ Original settings - BEGIN ============'
        Write-Host $content
        Write-Host '============ Original settings - END ============'
        Write-Host `r`n
        $modifiedPort = $configData.gitConfig.repository.modifiedPort
        $modifiedContent = $content -replace "url(\s)?=(\s)?http(s)?://([^:/]+):([0-9]+)(/?.*)", "url`$1=`$2http`$3://`$4:$modifiedPort`$6"
        Write-Output $modifiedContent | Out-File $localRepositoryConfig

        Write-Host '============ Modified settings - BEGIN ============'
        Write-Host $modifiedContent
        Write-Host '============ Modified settings - END ============'
        Write-Host `r`n

        Write-Host 'Git �����[�g���|�W�g�� �� �|�[�g�ԍ��ύX���������܂����B'
        Write-Host `r`n
    }
}

######################
# main process       #
######################
Set-GitConfig $configPath
