#require "open-uri"
#require "FileUtils"
#require "zip" # do : gem --user-install rubyzip
require "csv"
require "mysql"

# CSV基準列名の定義
col_name = Array[
	"作品ID",
	"作品名",
	"作品名読み",
	"ソート用読み",
	"副題",
	"副題読み",
	"原題",
	"初出",
	"分類番号",
	"文字遣い種別",
	"作品著作権フラグ",
	"公開日",
	"最終更新日",
	"図書カードURL",
	"人物ID",
	"姓",
	"名",
	"姓読み",
	"名読み",
	"姓読みソート用",
	"名読みソート用",
	"姓ローマ字",
	"名ローマ字",
	"役割フラグ",
	"生年月日",
	"没年月日",
	"人物著作権フラグ",
	"底本名1",
	"底本出版社名1",
	"底本初版発行年1",
	"入力に使用した版1",
	"校正に使用した版1",
	"底本の親本名1",
	"底本の親本出版社名1",
	"底本の親本初版発行年1",
	"底本名2",
	"底本出版社名2",
	"底本初版発行年2",
	"入力に使用した版2",
	"校正に使用した版2",
	"底本の親本名2",
	"底本の親本出版社名2",
	"底本の親本初版発行年2",
	"入力者",
	"校正者",
	"テキストファイルURL",
	"テキストファイル最終更新日",
	"テキストファイル符号化方式",
	"テキストファイル文字集合",
	"テキストファイル修正回数",
	"XHTML/HTMLファイルURL",
	"XHTML/HTMLファイル最終更新日",
	"XHTML/HTMLファイル符号化方式",
	"XHTML/HTMLファイル文字集合",
	"XHTML/HTMLファイル修正回数"
]


=begin
## get zip file
def save_image(url)
  # ready filepath
  fileName = File.basename(url)
  dirName = "./"
  filePath = dirName + fileName

  # create folder if not exist
  FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)

  # write image adata
  open(filePath, 'wb') do |output|
    open(url) do |data|
      output.write(data.read)
    end
  end
end

url = "http://www.aozora.gr.jp/index_pages/list_person_all_extended_utf8.zip"
save_image(url)


## unzip download zip file to csv file
Zip::File.open("./list_person_all_extended_utf8.zip") do |zip|
  zip.each do |entry|
    puts "entry #{entry.to_s}"
    # { true } は展開先に同名ファイルが存在する場合に上書きする指定
    zip.extract(entry, entry.to_s) { true }
  end
end
=end

## load csv file
#table = CSV.table('list_person_all_extended_utf8.csv')
is_header_row = true
i = 0
data_list = [];
CSV.foreach("list_person_all_extended_utf8.csv", { :encoding => "BOM|UTF-8", :col_sep => ",", :quote_char => '"' }) do |row|

    if is_header_row then
        # 各業を列毎に回す
        row.each do |col_value|
            # 各項目名（項目内容）に変わりが無いか確認
            if col_name[i] != col_value then
                p 'base column : ' + col_name[i]
                p 'csv column : ' + col_value
                p 'col name is changed'

                ## todo add notification system

                exit;
            end
            i += 1
        end
        is_header_row = false
    else
        # 各行のデータを配列へつっこみますん
        data_list << row
    end

end

## insert into Mysql
connection = Mysql::new("127.0.0.1", "root", "hoge", "aozora")
connection.charset = "utf8"
result = connection.query("set names utf8")
data_list.each_with_index do |row, k|
        author_data = []
        book_data = []
        row.each_with_index do |data, i|
                data = connection.quote(data)
                if i < 14 || i > 26 then
                        book_data << data
                elsif i == 14 then
                        book_data << data
                        author_data << data
                elsif i < 27 then
                        author_data << data
                end

        end


        book_data << nil # body
        book_data << nil # new_flag
        insert_str = "insert ignore into book values ('"
        insert_str += book_data.join("','").gsub("''", 'null')
        insert_str += "')"
        result = connection.query(insert_str)

        insert_str2 = "insert ignore into author values ('"
        insert_str2 += author_data.join("','").gsub("''", 'null')
        insert_str2 += "')"
        result = connection.query(insert_str2)
        p k

end

connection.close

# file削除


