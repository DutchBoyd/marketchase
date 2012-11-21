require './marketchase'

describe Marketchase do
  let(:mock_list) { double() }
  let(:mock_dbh) { double() }

  before do
    Marketchase.stub!(:open).and_return mock_list
    mock_list.stub!(:readlines).and_return []
    Mysql.stub!(:new).and_return mock_dbh
    mock_dbh.stub!(:close)
  end

  describe '#run' do
    it 'fetches the latest pricelist' do
      pricelist_url = 'http://supernovabots.com/prices_6.txt'
      Marketchase.should_receive(:open).with(pricelist_url).and_return mock_list
      Marketchase.run
    end

    it 'inserts price values for a booster pack' do
      booster = 'Masters Edition IV Booster [ME4]                   5.87      6.05      pisiiki2[13] tina16[13] pisiiki3[30] supernova01[14] mteamtester[3] bifidus[6] ComparePrices[7] '
      mock_list.should_receive(:readlines).and_return [booster]
      mock_dbh.should_receive(:query).with("INSERT INTO boosters (MTGSet, BuyPrice, SellPrice) VALUES ('ME4', '5.87', '6.05')")
      Marketchase.run
    end
  end
end
