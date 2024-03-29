function New-StrongPassword {
        <#
    .SYNOPSIS
        This script will generate a new strong password in Powershell using Special Characters, Uppercase Letters, Lowercase Letters and Numbers
    .EXAMPLE
        PS C:\> New-StrongPassword -Count 10 -Length 32

        This will generate 10 strong passwords with each having the length of 32.
    .Example
        PS C:\> New-StrongPassword -Count 10 -Length 32 -ExportableOutput

        This will generate 10 strong passwords with each having the length of 32 and arrange the output into a multi-dimensional array, for use with CSV-exports.
    .EXAMPLE
        PS C:\> New-StrongPassword -Count 10 -ExcludeSpecialCharacters

        This will generate 10 passwords without any special characters
    .PARAMETER Count
        Set the desired passwords to be generated
    .PARAMETER Length
        Set the desired length of the password(s)
    .PARAMETER ExportableOutput
        Include or set to $True to have the output organized into a multi-dimensional array, for use with CSV-exports.

        Example:
        PS C:\> New-StrongPassword -Count 10 -ExportableOutput | Export-CSV -Path Output.csv -Encoding UTF8 -Delimiter ";"
    .PARAMETER ExcludeUppercaseLetters
        Include or set to $True to exclude any uppercase letters 
    .PARAMETER ExcludeLowercaseLetters
        Include or set to $True to exclude any lowercase letters 
    .PARAMETER ExcludeNumbers
        Include or set to $True to exclude any numbers
    .PARAMETER ExcludeSpecialCharacters
        Include or set to $True to exclude any special characters 
    .NOTES
        MIT License

        Copyright (C) 2021 Niklas J. MacDowall. All rights reserved.

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the ""Software""), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:
        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.
        THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.

        AUTHOR: Niklas J. MacDowall (niklasjumlin [at] gmail [dot] com)
        LASTEDIT: May 09, 2023
    .LINK
        http://blog.jumlin.com
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $False, 
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Provide how many passwords that should be generated"
        )]
        [ValidateNotNullorEmpty()]
        #[ValidateScript({$_ -ge 1},ErrorMessage="Count value must be greater than {0}")]
        [ValidateScript({
            if (-not($_ -ge 1)) { 
                throw "Count value must be greater than $($_)"
            } else { 
                return $true
            }
        })]
        [Int]$Count = 1,
        
        [Parameter(
            Mandatory = $False, 
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Provide the desired length"
        )]
        #[ValidateScript({$_ -ge 1},ErrorMessage="Length value must be greater than {0}")]
        [ValidateScript({
            if (-not($_ -ge 6)) {
                throw "Length value must be greater than $($_)"
            } else {
                return $true
            }
        })]
        [Int]$Length = 16,
        
        [Parameter(
            Mandatory = $False, 
            HelpMessage = "Return generated passwords as an exportable multi-dimensional array (for csv-exports) or as a hashtable"
        )]
        [Switch]$ExportableOutput,
        
        [Parameter(
            Mandatory = $False, 
            HelpMessage = "If generated password should exclude uppercase letters"
        )]
        [Switch]$ExcludeUppercaseLetters,
        
        [Parameter(
            Mandatory = $False, 
            HelpMessage = "If generated password should exclude lowercase letters"
        )]
        [Switch]$ExcludeLowercaseLetters,
        
        [Parameter(
            Mandatory = $False, 
            HelpMessage = "If generated password should exclude numbers 1-9 or not"
        )]
        [Switch]$ExcludeNumbers,
        
        [Parameter(
            Mandatory = $False, 
            HelpMessage = "Exclude special characters or not"
        )]
        [Switch]$ExcludeSpecialCharacters,

        [Parameter(
            Mandatory = $False, 
            HelpMessage = "Specify special characters to include. (Default: !`"#$%&''()*+,-./:;<=>?@[\]^_`{|}~)"
        )]
        [string]$Specials
    )

    BEGIN {
        if ( ($ExcludeUppercaseLetters) -and ($ExcludeLowercaseLetters) -and ($ExcludeNumbers) -and ($ExcludeSpecialCharacters) ) {
            Write-Error "You must select at least one character type to be included in the generation. These can be either lowercase letters, uppercase letters, numbers or specials or all of them together."
            Continue
        }

        # Alphabet: Uppercase
        $AllUppercaseLetters = (65..90) | ForEach-Object {[char]$_}

        # Alphabet: Lowercase
        $AllLowercaseLetters = (97..122) | ForEach-Object {[char]$_}

        # Digits: 0-9 
        #$AllNumbers = (48..57) | % { [char]$_ }
        $AllNumbers = (0..9)

        # Specials: !"#$%&'()*+,-./:;<=>?@[\]^_`{}|~
        $AllSpecials = @{}
        (33..47) + (58..64) + (91..96) + (123..126) | ForEach-Object { $AllSpecials.[char]$_ = [byte]$_ }

        # if user has not excluded special characters AND has chosen custom special characters to be used
        if ((-not($ExcludeSpecialCharacters)) -and $Specials) {

            # Verify selected specials chars from available specials chars
            $CharSelection = foreach ($char in $Specials.ToCharArray()) {
                $AllSpecials.GetEnumerator().Where{$_.Key -eq "$char"}.Value
                if (-not($char -in $AllSpecials.Keys)) { Write-Warning "Unsupported special character included: `'$char`' (This will not be included)" }
            }

            # Set special characters to the user-selected special characters
            $AllSpecials = $CharSelection | ForEach-Object { [char]$_ }
        } else {
            # Since our original collection was a hashtable with key + value pairs, lets just grab the key labels
            $AllSpecials = $AllSpecials.Keys
        }

        $Selection=@()
        if (-not($ExcludeUppercaseLetters)) { 
            $Selection = $Selection + $AllUppercaseLetters 
        }
        if (-not($ExcludeLowercaseLetters)) { 
            $Selection = $Selection + $AllLowercaseLetters 
        }
        if (-not($ExcludeNumbers)) { 
            $Selection = $Selection + $AllNumbers 
        }
        if (-not($ExcludeSpecialCharacters)) { 
            $Selection = $Selection + $AllSpecials
        }


    }
    PROCESS {
        try {
            if ($Count -eq "1") {
                $NewPasswords = ($Selection | Get-Random -Count $Length) -join ""
            } else {
                if ($ExportableOutput) {
                    $NewPasswords = [System.Collections.Generic.List[PSCustomObject]]@()
                } else {
                    $NewPasswords = [Ordered]@{}
                }
                $i=1;while ($i -le $Count) {
                    if ($ExportableOutput) {
                        $NewPassword = [PSCustomObject]@{ 
                            "PasswordNumber" = $i
                            "PasswordValue"  = ($Selection | Get-Random -Count $Length) -join ""
                        }
                        $NewPasswords.Add($NewPassword)
                    } else {
                        $NewPasswords."Password $i" = ($Selection | Get-Random -Count $Length) -join ""
                    }
                    $i++
                }
            }
        } catch {
            Write-Error $_.Exception.Message
        }
    }
    END {
        [PSCustomObject]$NewPasswords
    }
}