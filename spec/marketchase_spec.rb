require './marketchase'

describe Marketchase do
  describe '#run' do
    let(:mock_list) { double() }
    let(:mock_dbh) { double() }

    before do
      subject.stub!(:open).and_return mock_list
      mock_list.stub!(:readlines).and_return []
      Mysql.stub!(:new).and_return mock_dbh
      mock_dbh.stub!(:close)
    end


    it 'fetches the latest pricelist' do
      pricelist_url = 'http://supernovabots.com/prices_6.txt'
      subject.should_receive(:open).with(pricelist_url).and_return mock_list
      subject.run
    end

    it 'inserts price values for a booster pack' do
      subject.should_receive(:booster_parse).and_return(set: 'ME4', buy: '5.87', sell: '6.05')
      mock_list.should_receive(:readlines).and_return(['some line'])
      mock_dbh.should_receive(:query).with("INSERT INTO boosters (MTGSet, BuyPrice, SellPrice) VALUES ('ME4', '5.87', '6.05')")
      subject.run
    end
  end

  describe '#booster_parse' do
    let(:booster_with_empty_buy)   { 'Shards of Alara Block Booster Pack [F10]                     1.54      ComparePrices[14] pisiiki2[2] bifidus[15] supernova02[1]' }
    let(:booster_with_empty_sell)  { 'Eventide Booster [EVE]                             3.73                bifidus[8] pisiiki3[6] mteamtester[5] ComparePrices[9] tina16[10] pisiiki2[6] ' }
    let(:booster_with_all_amounts) { 'Masters Edition IV Booster [ME4]                   5.87      6.05      pisiiki2[13] tina16[13] pisiiki3[30] supernova01[14] mteamtester[3] bifidus[6] ComparePrices[7] ' }

    it 'parses a line with only set and sell amount' do
      res = subject.booster_parse(booster_with_empty_buy)
      res[:buy].should be nil
      res[:sell].should eq '1.54'
      res[:set].should eq 'F10'
    end

    it 'parses a line with only set and buy amount' do
      res = subject.booster_parse(booster_with_empty_sell)
      res[:buy].should eq '3.73'
      res[:sell].should be nil
      res[:set].should eq 'EVE'
    end

    it 'parses a line with set and both amounts' do
      res = subject.booster_parse(booster_with_all_amounts)
      res[:buy].should eq '5.87'
      res[:sell].should eq '6.05'
      res[:set].should eq 'ME4'
    end

    it 'returns nil without a match' do
      nonconforming_line = 'A man must consider what a rich realm he abdicates when he becomes a conformist. - Ralph Waldo Emerson'
      subject.booster_parse(nonconforming_line).should be_nil
    end
  end
end
