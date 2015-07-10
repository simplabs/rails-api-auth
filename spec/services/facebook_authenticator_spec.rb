require 'spec_helper'

describe FacebookAuthenticator do
  describe '#authenticate' do
    let(:auth_code) { 'authcode' }
    let(:email)     { 'email@facebook.com' }
    let(:facebook_data) do
      {
        id:         '1238190321',
        email:      email
      }
    end
    let(:response_with_fb_token) { { body: '{ "access_token": "access_token" }' } }
    let(:response_with_fb_user)  { { body: JSON.generate(facebook_data), headers: { 'Content-Type' => 'application/json' } } }
    let(:login)                  { double('login') }

    subject { described_class.new(auth_code).authenticate }

    before do
      stub_request(:get, %r{https://graph.facebook.com/v2.3/oauth/access_token}).to_return(response_with_fb_token)
      stub_request(:get, %r{https://graph.facebook.com/v2.3/me}).to_return(response_with_fb_user)
    end

    context 'new login' do
      let(:login_attributes) do
        {
          email:        facebook_data[:email],
          facebook_uid: facebook_data[:id]
        }
      end

      before do
        allow(Login).to receive(:create!).with(login_attributes).and_return login
      end

      it 'returns a login created from facebook account' do
        expect(subject).to eql login
      end
    end

    context 'existing login' do
      before do
        expect(Login).to receive(:find_by).with(email: facebook_data[:email]).and_return login
        allow(login).to receive(:update_attributes!).with(facebook_uid: facebook_data[:id])
      end

      it 'connects login to facebook account' do
        expect(login).to receive(:update_attributes!).with(facebook_uid: facebook_data[:id])

        subject
      end
    end
  end
end
