#Backup - readme
##Co to umi
Pogram slouzi k zalohovani souboru. Funguje tak, že se mu řekne, kterou složku má zálohovat a on ji zálohuje do složky *-backup. Program dělá to, že pokud se jedna složka zálohuje víckrát, neukládá si zálohy celé znova, ale "rozdílově". Ve složkách jednotlivých záloh tedy není přesně to, co tato složka zálohuje, ale jen to "co není jinde". Informace o tom, které další soubory mají v záloze být a o tom, kde jsou, je uloženo v souboru *.diff.

Protože ve složce se zálohou není přesně to, čemu záloha odpovídá, další část programu dělá to, že z této složky s rozdílovou zálohou udělá "normální složku" - tedy složku, ve které je přesně to, co záloha zálohovala.

##Jak se to ovládá
Kod je v **backup.sh**. Nastavuji se mu tyto veci:

**-b** *STRING*		Zalohuje slozku STRING a zalohy uklada do STRING-backup. Zálohy pojmenovává podle data a času

**-u** *STRING1 STRING2*	Ulozenou zalohu STRING1 (cesta k nejake slozce v *-backup) slozi a ulozi do slozky STRING2.

Prepinacem **-e** se rekne programu, ze ma byt ukecany.
